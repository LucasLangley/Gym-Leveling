// Em lib/screens/ranking_screen.dart
// ignore_for_file: prefer_const_constructors, avoid_print, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_other_profile_screen.dart';
import 'guild_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/translation_service.dart';
import '../utils/aura_calculator.dart' as aura_utils;
// Removendo import não utilizado
// import 'guild_profile_screen.dart';

// Cores (pode mover para um arquivo global de constantes)
const Color primaryColor = Color(0xFF0A0E21);
const Color accentColorBlue = Color(0xFF40C4FF);
const Color accentColorPurple = Color(0xFF8A2BE2);
const Color textColor = Colors.white;
const Color panelBgColor = Color(0x991D1E33);
const Color prColor = Colors.amberAccent; // Para destacar a aura ou valores no ranking

// Modelo para informações do ranking de jogadores
class PlayerRankingInfo {
  final String uid;
  final String playerName;
  final int displayValue;
  final int level;
  final String? photoUrl;
  final String? guildName;
  final String? region;

  PlayerRankingInfo({
    required this.uid,
    required this.playerName,
    required this.displayValue,
    required this.level,
    this.photoUrl,
    this.guildName,
    this.region,
  });

  factory PlayerRankingInfo.fromFirestore(DocumentSnapshot doc, String selectedDisplayFilter, Map<String, Map<String, dynamic>> sortOptions) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    int valueToDisplay = 0;
    int playerLevel = data['level'] ?? 1;

    if (selectedDisplayFilter == 'Aura Total') {
      Map<String, int> baseStats = Map<String, int>.from(data['stats'] ?? {});
      Map<String, int> bonusStats = Map<String, int>.from(data['bonusStats'] ?? {});
      String currentTitle = data['title'] ?? 'Aspirante';
      String currentJob = data['job'] ?? 'Nenhuma';
      Map<String, bool> completedAchievements = Map<String, bool>.from(data['completedAchievements'] ?? {});
      
      // Usar função centralizada para calcular aura total
             valueToDisplay = aura_utils.calculateTotalAura(
        baseStats: baseStats,
        bonusStats: bonusStats,
        currentTitle: currentTitle,
        currentJob: currentJob,
        level: playerLevel,
        completedAchievements: completedAchievements,
      );
    } else if (selectedDisplayFilter == 'Nível') {
      valueToDisplay = playerLevel;
    } else {
      String statKey = sortOptions[selectedDisplayFilter]!['label']!;
      Map<String, dynamic> baseStats = Map<String,dynamic>.from(data['stats'] ?? {});
      Map<String, dynamic> bonusStats = Map<String,dynamic>.from(data['bonusStats'] ?? {});
      
      // Para stats individuais, bonusStats já inclui os bônus dos itens
      valueToDisplay = ((baseStats[statKey] ?? 0) as int) + ((bonusStats[statKey] ?? 0) as int);
    }

    String? photoUrl = data['profileImageUrl'] as String?;

    return PlayerRankingInfo(
      uid: doc.id,
      playerName: data['playerName'] ?? 'N/A',
      displayValue: valueToDisplay,
      level: playerLevel,
      photoUrl: photoUrl,
      guildName: data['guildName'] as String?,
      region: data['region'] as String?,
    );
  }
}

// Modelo para informações do ranking de guildas
class GuildRankingInfo {
  final String id;
  final String name;
  final String ownerName;
  final int totalAura;
  final int memberCount;
  final String? iconUrl;
  final Map<String, dynamic> members; // Adicionando membros da guilda
  final String? region;

  GuildRankingInfo({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.totalAura,
    required this.memberCount,
    this.iconUrl,
    required this.members,
    this.region,
  });

  static Future<GuildRankingInfo> fromFirestore(DocumentSnapshot doc) async {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Calcula a aura total somando base + bônus de todos os membros
    int totalAura = 0;
    Map<String, dynamic> members = Map<String, dynamic>.from(data['members'] ?? {});
    
    // Busca os dados de cada membro sequencialmente
    for (var memberId in members.keys) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(memberId)
            .get();
        
        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          Map<String, int> baseStats = Map<String, int>.from(userData['stats'] ?? {});
          Map<String, int> bonusStats = Map<String, int>.from(userData['bonusStats'] ?? {});
          String currentTitle = userData['title'] ?? 'Aspirante';
          String currentJob = userData['job'] ?? 'Nenhuma';
          int level = userData['level'] ?? 1;
          Map<String, bool> completedAchievements = Map<String, bool>.from(userData['completedAchievements'] ?? {});
          
          // Usar função centralizada para calcular aura do membro
          int memberAura = aura_utils.calculateTotalAura(
            baseStats: baseStats,
            bonusStats: bonusStats,
            currentTitle: currentTitle,
            currentJob: currentJob,
            level: level,
            completedAchievements: completedAchievements,
          );
          
          totalAura += memberAura;
        }
      } catch (e) {
        print("Erro ao calcular aura do membro $memberId: $e");
      }
    }

    // Buscar região do dono da guilda
    String? guildRegion;
    try {
      String ownerId = data['ownerId'] ?? '';
      if (ownerId.isNotEmpty) {
        DocumentSnapshot ownerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(ownerId)
            .get();
        if (ownerDoc.exists && ownerDoc.data() != null) {
          Map<String, dynamic> ownerData = ownerDoc.data() as Map<String, dynamic>;
          guildRegion = ownerData['region'] as String?;
        }
      }
    } catch (e) {
      print("Erro ao buscar região do dono da guilda: $e");
    }

    return GuildRankingInfo(
      id: doc.id,
      name: data['name'] ?? 'Guilda Desconhecida',
      ownerName: data['ownerName'] ?? 'N/A',
      totalAura: totalAura,
      memberCount: data['memberCount'] ?? 0,
      iconUrl: data['iconUrl'] as String?,
      members: members,
      region: guildRegion,
    );
  }
}

enum RankingType { players, guilds }

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> with SingleTickerProviderStateMixin {
  bool _isLoadingPlayers = true;
  bool _isLoadingGuilds = true;
  List<PlayerRankingInfo> _playerRankings = [];
  List<GuildRankingInfo> _guildRankings = [];
  List<PlayerRankingInfo> _filteredPlayerRankings = [];
  List<GuildRankingInfo> _filteredGuildRankings = [];
  
  final TextEditingController _playerSearchController = TextEditingController();
  final TextEditingController _guildSearchController = TextEditingController();


  
  String _selectedPlayerSortFilter = 'Aura Total';
  String _selectedRegionFilter = 'Todas as Regiões';
  
  final List<String> _regionOptions = [
    'Todas as Regiões',
    'América do Norte',
    'América do Sul',
    'Europa',
    'Ásia',
    'África',
    'Oceania',
  ];
  final Map<String, Map<String, dynamic>> _playerSortOptions = {
    'Aura Total': {'label': 'Aura Total', 'icon': Icons.whatshot_rounded},
    'Força': {'label': 'FOR', 'icon': Icons.fitness_center},
    'Vitalidade': {'label': 'VIT', 'icon': Icons.favorite_border_rounded},
    'Agilidade': {'label': 'AGI', 'icon': Icons.directions_run_rounded},
    'Inteligência': {'label': 'INT', 'icon': Icons.psychology_outlined},
    'Percepção': {'label': 'PER', 'icon': Icons.visibility_outlined},
    'Nível': {'label': 'level', 'icon': Icons.military_tech_rounded},
  };

  RankingType _selectedRankingType = RankingType.players;
  TabController? _tabController;

  Widget _buildDialogButton(BuildContext passedContext, String text, VoidCallback onPressed, bool isPrimary) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? accentColorPurple : Colors.grey.shade700,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: isPrimary ? accentColorBlue : Colors.transparent)
        ),
      ),
      child: Text(text.toUpperCase()),
    );
  }

  Future<T?> _showStyledDialog<T>({
    required BuildContext passedContext,
    required String titleText,
    required List<Widget> contentWidgets,
    required List<Widget> actions,
    IconData icon = Icons.info_outline,
    Color iconColor = accentColorBlue,
  }) {
    return showDialog<T>(
      context: passedContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: primaryColor.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
            side: BorderSide(color: accentColorBlue.withOpacity(0.7), width: 1.5),
          ),
          title: Container(
            padding: const EdgeInsets.only(bottom: 10.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: accentColorPurple.withOpacity(0.5), width: 1.0)
              )
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 10),
                Text(
                  titleText.toUpperCase(),
                  style: const TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(children: contentWidgets),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
          actions: actions.length > 1
              ? List.generate(actions.length * 2 - 1, (index) {
                  if (index.isEven) return actions[index ~/ 2];
                  return const SizedBox(width: 8);
                })
              : actions,
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(() {
      if (mounted) {
        if (_tabController!.indexIsChanging) {
          // Não faz nada durante a transição da aba
        } else {
          if (_selectedRankingType != RankingType.values[_tabController!.index]) {
            setState(() {
              _selectedRankingType = RankingType.values[_tabController!.index];
            });
            if (_selectedRankingType == RankingType.players && _playerRankings.isEmpty) {
              _fetchPlayerRankings();
            } else if (_selectedRankingType == RankingType.guilds && _guildRankings.isEmpty) {
              _fetchGuildRankings();
            }
          }
        }
      }
    });
    _fetchPlayerRankings();
    _fetchGuildRankings();

    // Adicionar listeners para os controladores de busca
    _playerSearchController.addListener(_filterPlayers);
    _guildSearchController.addListener(_filterGuilds);
  }

  @override
  void dispose() {
    _playerSearchController.dispose();
    _guildSearchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  void _filterPlayers() {
    final query = _playerSearchController.text.toLowerCase();
    setState(() {
      _filteredPlayerRankings = _playerRankings.where((player) {
        // Filtro por busca
        bool matchesSearch = player.playerName.toLowerCase().contains(query) ||
               (player.guildName?.toLowerCase().contains(query) ?? false);
        
        // Filtro por região
        bool matchesRegion = _selectedRegionFilter == 'Todas as Regiões' ||
               player.region == _selectedRegionFilter;
        
        return matchesSearch && matchesRegion;
      }).toList();
    });
  }

  void _filterGuilds() {
    final query = _guildSearchController.text.toLowerCase();
    setState(() {
      _filteredGuildRankings = _guildRankings.where((guild) {
        // Filtro por busca
        bool matchesSearch = guild.name.toLowerCase().contains(query) ||
               guild.ownerName.toLowerCase().contains(query);
        
        // Filtro por região
        bool matchesRegion = _selectedRegionFilter == 'Todas as Regiões' ||
               guild.region == _selectedRegionFilter;
        
        return matchesSearch && matchesRegion;
      }).toList();
    });
  }

  Future<void> _fetchPlayerRankings() async {
    if (!mounted) return;
    setState(() { _isLoadingPlayers = true; });

    try {
      print('DEBUG: Buscando ranking, filtro: $_selectedPlayerSortFilter');
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      print('DEBUG: Total de documentos retornados para ranking: ${querySnapshot.docs.length}');
      
      List<PlayerRankingInfo> rankings = querySnapshot.docs.map((doc) {
          return PlayerRankingInfo.fromFirestore(doc, _selectedPlayerSortFilter, _playerSortOptions);
      }).toList();

      rankings.sort((a, b) => b.displayValue.compareTo(a.displayValue));

      if (mounted) {
        setState(() {
          _playerRankings = rankings;
          _filteredPlayerRankings = rankings;
          _isLoadingPlayers = false;
        });
      }
      print('DEBUG: Ranking carregado e ordenado no cliente.');
    } catch (e, s) {
      print("ERRO ao buscar ranking de jogadores: $e\nStack: $s");
      if (mounted) {
        setState(() { _isLoadingPlayers = false; });
        _showStyledDialog(
          passedContext: context,
          titleText: TranslationService.get('error', Provider.of<LanguageService>(context, listen: false).currentLanguageCode),
          icon: Icons.error_outline,
          iconColor: Colors.redAccent,
          contentWidgets: [
            Text(
              TranslationService.get('errorLoadingPlayerRanking', Provider.of<LanguageService>(context, listen: false).currentLanguageCode),
              textAlign: TextAlign.center,
              style: const TextStyle(color: textColor, fontSize: 16)
            )
          ],
          actions: [
            _buildDialogButton(context, TranslationService.get('ok', Provider.of<LanguageService>(context, listen: false).currentLanguageCode), () => Navigator.of(context).pop(), true)
          ],
        );
      }
    }
  }

  Future<void> _fetchGuildRankings() async {
    if (!mounted) return;
    setState(() { _isLoadingGuilds = true; });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('guilds')
          .orderBy('totalAura', descending: true)
          .limit(100)
          .get();

      List<GuildRankingInfo> rankings = [];
      for (var doc in querySnapshot.docs) {
        rankings.add(await GuildRankingInfo.fromFirestore(doc));
      }

      if (mounted) {
        setState(() {
          _guildRankings = rankings;
          _filteredGuildRankings = rankings;
          _isLoadingGuilds = false;
        });
      }
    } catch (e) {
      print("Erro ao buscar ranking de guildas: $e");
      if (mounted) {
        setState(() { _isLoadingGuilds = false; });
        _showStyledDialog(
          passedContext: context,
          titleText: TranslationService.get('error', Provider.of<LanguageService>(context, listen: false).currentLanguageCode),
          icon: Icons.error_outline,
          iconColor: Colors.redAccent,
          contentWidgets: [
            Text(
              TranslationService.get('errorLoadingGuildRanking', Provider.of<LanguageService>(context, listen: false).currentLanguageCode),
              textAlign: TextAlign.center,
              style: const TextStyle(color: textColor, fontSize: 16)
            )
          ],
          actions: [
            _buildDialogButton(context, TranslationService.get('ok', Provider.of<LanguageService>(context, listen: false).currentLanguageCode), () => Navigator.of(context).pop(), true)
          ],
        );
      }
    }
  }

  Widget _buildPlayerRankingList() {
    if (_isLoadingPlayers) return Center(child: CircularProgressIndicator(color: accentColorPurple));
    if (_filteredPlayerRankings.isEmpty) return Center(child: Text(TranslationService.get('noPlayersFound', Provider.of<LanguageService>(context, listen: false).currentLanguageCode), style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 16)));
    
    return RefreshIndicator(
      onRefresh: _fetchPlayerRankings,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        itemCount: _filteredPlayerRankings.length,
        itemBuilder: (context, index) {
          final player = _filteredPlayerRankings[index];
          final isCurrentUser = player.uid == FirebaseAuth.instance.currentUser?.uid;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0.0),
            color: isCurrentUser ? accentColorPurple.withOpacity(0.4) : panelBgColor.withOpacity(0.6),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ViewOtherProfileScreen(userId: player.uid)));
              },
              borderRadius: BorderRadius.circular(12.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Posição no ranking
                    SizedBox(
                      width: 40, // Aumentar largura para acomodar a estrela e o número
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.star_rounded, color: accentColorPurple, size: 36), // Estrela
                          Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: textColor, // Cor branca para o número
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    // Foto de perfil do jogador
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: accentColorBlue.withOpacity(0.3),
                      backgroundImage: player.photoUrl != null && player.photoUrl!.isNotEmpty
                          ? NetworkImage(player.photoUrl!)
                          : null,
                      child: player.photoUrl == null || player.photoUrl!.isEmpty
                          ? Icon(Icons.person, color: textColor.withOpacity(0.7), size: 25)
                          : null,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.playerName,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.whatshot_rounded, color: prColor, size: 14), // Ícone de chama para aura
                              SizedBox(width: 4), // Espaço entre ícone e texto
                                                              Text(
                                  'Aura: ${player.displayValue}',
                                  style: TextStyle(
                                    color: prColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (player.guildName != null && player.guildName!.isNotEmpty) ...[
                                  SizedBox(width: 8), // Espaço entre a aura e a guilda
                                  Icon(Icons.shield_rounded, color: prColor, size: 14), // Ícone de escudo para guilda
                                  SizedBox(width: 4), // Espaço entre ícone e texto
                                  Flexible(
                                    child: Text(
                                      'Guilda: ${player.guildName}',
                                      style: TextStyle(color: prColor, fontSize: 12, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, color: textColor.withOpacity(0.5), size: 18),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuildRankingList() {
    if (_isLoadingGuilds) return Center(child: CircularProgressIndicator(color: accentColorPurple));
    if (_filteredGuildRankings.isEmpty) return Center(child: Text(TranslationService.get('noGuildsFound', Provider.of<LanguageService>(context, listen: false).currentLanguageCode), style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 16)));

    return RefreshIndicator(
      onRefresh: _fetchGuildRankings,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        itemCount: _filteredGuildRankings.length,
        itemBuilder: (context, index) {
          final guild = _filteredGuildRankings[index];
          return Card(
            color: panelBgColor.withOpacity(0.7),
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: SizedBox(
                width: 40, // Largura para o stack da estrela
                height: 40, // Altura para o stack da estrela
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.star_rounded, color: accentColorPurple, size: 36), // Ícone de estrela com cor roxa
                    Text(
                      "${_guildRankings.indexOf(guild) + 1}", // Número do rank
                      style: TextStyle(
                        color: textColor, // Cor branca para o número
                        fontSize: 14, // Tamanho da fonte para o número
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              title: Text(guild.name, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("${TranslationService.get('leader', Provider.of<LanguageService>(context, listen: false).currentLanguageCode)}: ${guild.ownerName}", style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 12)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.whatshot_rounded, color: prColor, size: 14), // Ícone de chama para aura
                      SizedBox(width: 4), // Espaço entre ícone e texto
                      Text("${TranslationService.get('totalAura', Provider.of<LanguageService>(context, listen: false).currentLanguageCode)}: ${guild.totalAura} | ${TranslationService.get('members', Provider.of<LanguageService>(context, listen: false).currentLanguageCode)}: ${guild.memberCount}", style: TextStyle(color: prColor, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
              trailing: Icon(Icons.arrow_forward_ios_rounded, color: accentColorBlue.withOpacity(0.7), size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GuildProfileScreen(guildId: guild.id),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField(TextEditingController controller, String hintText) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: panelBgColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColorBlue.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
          prefixIcon: Icon(Icons.search, color: accentColorBlue.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildRegionFilter() {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        String t(String key) => TranslationService.get(key, languageService.currentLanguageCode);
        
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: panelBgColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accentColorBlue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on_rounded, color: accentColorBlue.withOpacity(0.7), size: 20),
              SizedBox(width: 12),
              Text(t('region'), style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 14)),
              SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRegionFilter,
                    dropdownColor: panelBgColor,
                    icon: Icon(Icons.arrow_drop_down_rounded, color: accentColorBlue),
                    style: TextStyle(color: textColor, fontSize: 14),
                    isExpanded: true,
                    items: _regionOptions.map((String region) {
                      return DropdownMenuItem<String>(
                        value: region,
                        child: Text(region == 'Todas as Regiões' ? t('allRegions') : region, style: TextStyle(color: textColor)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedRegionFilter = newValue;
                        });
                        _filterPlayers();
                        _filterGuilds();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        String t(String key) => TranslationService.get(key, languageService.currentLanguageCode);
        
        return Scaffold(
          backgroundColor: primaryColor,
          appBar: AppBar(
            title: Text(t('globalRanking'), style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
            backgroundColor: primaryColor,
            elevation: 0,
            iconTheme: IconThemeData(color: accentColorBlue),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: accentColorPurple,
              labelColor: accentColorPurple,
              unselectedLabelColor: textColor.withOpacity(0.7),
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              tabs: [
                Tab(text: t('players')),
                Tab(text: t('guilds')),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              Column(
                children: [
                  _buildSearchField(_playerSearchController, t('searchPlayerOrGuild')),
                  _buildRegionFilter(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sort_by_alpha_rounded, color: accentColorBlue.withOpacity(0.8), size: 20),
                        SizedBox(width: 8),
                        Text(t('sortBy'), style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 14)),
                        SizedBox(width: 12),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPlayerSortFilter,
                            dropdownColor: panelBgColor,
                            icon: Icon(Icons.arrow_drop_down_rounded, color: accentColorBlue),
                            style: TextStyle(color: textColor, fontSize: 14),
                            items: _playerSortOptions.keys.map((String key) {
                              return DropdownMenuItem<String>(
                                value: key,
                                child: Row(
                                  children: [
                                    Icon(_playerSortOptions[key]!['icon'] as IconData, color: key == 'Aura Total' ? prColor : accentColorBlue.withOpacity(0.9), size: 18),
                                    SizedBox(width: 8),
                                    Text(key),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedPlayerSortFilter = newValue;
                                });
                                _fetchPlayerRankings();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: accentColorBlue.withOpacity(0.2), height: 1, thickness: 0.5),
                  Expanded(child: _buildPlayerRankingList()),
                ],
              ),
              Column(
                children: [
                  _buildSearchField(_guildSearchController, t('searchGuildOrLeader')),
                  _buildRegionFilter(),
                  Expanded(child: _buildGuildRankingList()),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}