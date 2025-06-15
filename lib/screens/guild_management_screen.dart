// Em lib/screens/guild_management_screen.dart
// ignore_for_file: prefer_const_constructors, avoid_print, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/aura_calculator.dart' as aura_utils;
import 'dart:async'; // Importe para usar StreamSubscription
// Se usado para Random ID no placeholder de Mission

// Cores
const Color primaryColor = Color(0xFF0A0E21);
const Color accentColorBlue = Color(0xFF40C4FF);
const Color accentColorPurple = Color(0xFF8A2BE2);
const Color textColor = Colors.white;
const Color panelBgColor = Color(0x991D1E33);
const Color yellowWarningColor = Colors.yellowAccent;
const Color prColor = Colors.amberAccent; 

// Modelo para Guilda
class Guild {
  final String id;
  final String name;
  final String ownerId;
  final String ownerName;
  final String description;
  final String? iconUrl;
  final int? iconData;
  final String? iconFontFamily;
  final String? iconFontPackage;
  final Timestamp createdAt;
  final int memberCount;
  final int totalAura;
  final Map<String, String> members;

  Guild({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.ownerName,
    this.description = "Nenhuma descrição definida.",
    this.iconUrl,
    this.iconData,
    this.iconFontFamily,
    this.iconFontPackage,
    required this.createdAt,
    required this.memberCount,
    required this.totalAura,
    required this.members,
  });

  factory Guild.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Guild(
      id: doc.id,
      name: data['name'] ?? 'Guilda Desconhecida',
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? 'Dono Desconhecido',
      description: data['description'] ?? 'Nenhuma descrição definida.',
      iconUrl: data['iconUrl'] as String?,
      iconData: data['iconData'] as int?,
      iconFontFamily: data['iconFontFamily'] as String?,
      iconFontPackage: data['iconFontPackage'] as String?,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      memberCount: data['memberCount'] ?? 0,
      totalAura: data['totalAura'] ?? 0,
      members: Map<String, String>.from(data['members'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'members': members,
      'memberCount': memberCount,
      'totalAura': totalAura,
      'createdAt': createdAt,
      'iconData': iconData,
      'iconFontFamily': iconFontFamily,
      'iconFontPackage': iconFontPackage,
    };
  }
}

// Modelo auxiliar para exibir informações de membros
class GuildMemberInfo {
  final String uid;
  final String name;
  final String role;
  final int aura;
  final int level;
  final String? photoUrl;

  GuildMemberInfo({
    required this.uid,
    required this.name,
    required this.role,
    required this.aura,
    required this.level,
    this.photoUrl,
  });
}

class GuildManagementScreen extends StatefulWidget {
  const GuildManagementScreen({super.key});

  @override
  State<GuildManagementScreen> createState() => _GuildManagementScreenState();
}

class _GuildManagementScreenState extends State<GuildManagementScreen> with SingleTickerProviderStateMixin {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  bool _isProcessingAction = false;
  String? _userGuildId;
  Guild? _currentGuildDetails;
  List<GuildMemberInfo> _guildMembersList = [];
  bool _isLoadingMembers = false;
  StreamSubscription? _guildListenerSubscription;
  IconData _selectedGuildIcon = Icons.shield_outlined;
  late TabController _tabController;
  List<Map<String, dynamic>> _joinRequests = [];
  bool _isLoadingRequests = false;

  // Variáveis para ordenação
  String _currentSort = 'cargo'; // 'cargo' ou 'aura'
  bool _isAscending = true;

  final TextEditingController _guildNameController = TextEditingController();
  final TextEditingController _guildDescriptionController = TextEditingController();
  final TextEditingController _invitePlayerNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkUserGuildStatus().then((_) {
      _setupGuildListener();
      if (_userGuildId != null) {
        _loadJoinRequests();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _guildNameController.dispose();
    _guildDescriptionController.dispose();
    _invitePlayerNameController.dispose();
    _guildListenerSubscription?.cancel();
    super.dispose();
  }

  // --- FUNÇÕES DE DIÁLOGO (AGORA SERÃO USADAS) ---
  Widget _buildDialogButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    Color? color,
    bool isLoading = false,
    bool fullWidth = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ElevatedButton.icon(
        icon: isLoading ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ) : Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? accentColorBlue,
          foregroundColor: Colors.white,
          minimumSize: fullWidth ? Size(double.infinity, 40) : null,
        ),
        onPressed: isLoading ? null : onPressed,
      ),
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
              border: Border(bottom: BorderSide(color: accentColorPurple.withOpacity(0.5), width: 1.0)),
            ),
            child: Row(children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 10),
              Text(titleText.toUpperCase(), style: const TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
            ]),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: contentWidgets,
            ),
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
  // --- FIM FUNÇÕES DE DIÁLOGO ---

  void _setupGuildListener() {
    // Certifique-se de que o listener anterior seja cancelado antes de configurar um novo
    _guildListenerSubscription?.cancel();

    if (_userGuildId != null) {
      _guildListenerSubscription = FirebaseFirestore.instance
          .collection('guilds')
          .doc(_userGuildId!)
          .snapshots()
          .listen((snapshot) {
        if (!snapshot.exists) {
          // Guilda foi excluída - limpar dados locais
          _cleanupAfterGuildDeletion();
        }
      }, onError: (error) {
        print("Erro no listener da guilda: $error");
        // Opcional: mostrar um erro para o usuário ou tentar reconectar
      });
       print("Listener da guilda configurado para ID: $_userGuildId");
    }
     else { print("Não configurou listener da guilda: _userGuildId é nulo");}
  }

  void _cleanupAfterGuildDeletion() async {
    // Limpar dados do usuário atual quando detectar que a guilda foi excluída
     if (_currentUser == null) return; // Verificação de segurança extra

    await FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).update({
      'guildId': null,
      'guildName': null,
      'guildRole': null,
    }).catchError((e) => print("Erro ao limpar dados do usuário após exclusão da guilda: $e"));

    if (mounted) {
      setState(() {
        _userGuildId = null;
        _currentGuildDetails = null;
        _guildMembersList = [];
      });

      _showStyledDialog(
        passedContext: context,
        titleText: "Removido da Guilda",
        icon: Icons.info_outline,
        iconColor: Colors.orange,
        contentWidgets: [
          Text("Você foi removido da guilda.", style: TextStyle(color: textColor)),
        ],
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK", style: TextStyle(color: accentColorBlue)),
          ),
        ],
      );
       // Cancela o listener após a limpeza
      _guildListenerSubscription?.cancel();
      _guildListenerSubscription = null;
    }
  }

  Future<void> _checkUserGuildStatus() async {
    if (_currentUser == null) {
      if (mounted) setState(() { _isLoading = false; });
      return;
    }
    if (!mounted) return;
    setState(() { _isLoading = true; });
    
    DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(_currentUser.uid);

    try {
      DocumentSnapshot userDoc = await userDocRef.get();
      _currentGuildDetails = null; // Reseta antes de carregar

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        _userGuildId = userData['guildId'] as String?;

        if (_userGuildId != null) {
          DocumentSnapshot guildDoc = await FirebaseFirestore.instance.collection('guilds').doc(_userGuildId!).get();
          if (guildDoc.exists) {
            _currentGuildDetails = Guild.fromFirestore(guildDoc);
            
            // Carregar o ícone da guilda
            Map<String, dynamic> guildData = guildDoc.data() as Map<String, dynamic>;
            if (guildData['iconData'] != null) {
              _selectedGuildIcon = _getIconFromData(
                guildData['iconData'] as int,
                guildData['iconFontFamily'] as String?,
                guildData['iconFontPackage'] as String?,
              );
            }
            
            await _fetchGuildMembers(_currentGuildDetails!.id, _currentGuildDetails!.members);
          } else {
            print("Inconsistência: Usuário tem guildId ($_userGuildId), mas a guilda não foi encontrada. Limpando dados do usuário.");
            await userDocRef.update({'guildId': null, 'guildName': null, 'guildRole': null});
            _userGuildId = null;
          }
        }
      } else {
         print("Documento do usuário não existe. Não é possível verificar o status da guilda.");
         _userGuildId = null;
      }
    } catch (e) {
      print("Erro ao verificar status da guilda do usuário: $e");
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _fetchGuildMembers(String guildId, Map<String, String> memberRoles) async {
    if (!mounted) return;
    setState(() { _isLoadingMembers = true; });
    List<GuildMemberInfo> membersTemp = [];
    int totalGuildAura = 0;
    try {
      for (var entry in memberRoles.entries) {
        String memberUid = entry.key;
        String role = entry.value;
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(memberUid).get();
        if (userDoc.exists) {
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
          
          totalGuildAura += memberAura;
          
          membersTemp.add(GuildMemberInfo(
            uid: memberUid,
            name: userData['playerName'] ?? 'Membro Desconhecido',
            role: role,
            aura: memberAura,
            level: userData['level'] ?? 1,
            photoUrl: userData['profileImageUrl'] as String?,
          ));
        }
      }
      membersTemp.sort((a, b) {
        int roleCompare = _rolePriority(a.role).compareTo(_rolePriority(b.role));
        if (roleCompare != 0) return roleCompare;
        return b.aura.compareTo(a.aura);
      });

      if(mounted){
        setState(() {
          _guildMembersList = membersTemp;
          if (_currentGuildDetails != null) {
            _currentGuildDetails = Guild(
              id: _currentGuildDetails!.id,
              name: _currentGuildDetails!.name,
              description: _currentGuildDetails!.description,
              ownerId: _currentGuildDetails!.ownerId,
              ownerName: _currentGuildDetails!.ownerName,
              members: _currentGuildDetails!.members,
              memberCount: _currentGuildDetails!.memberCount,
              totalAura: totalGuildAura,
              createdAt: _currentGuildDetails!.createdAt,
              iconData: _currentGuildDetails!.iconData,
              iconFontFamily: _currentGuildDetails!.iconFontFamily,
              iconFontPackage: _currentGuildDetails!.iconFontPackage,
            );
          }
        });
      }
    } catch (e) {
      print("Erro ao buscar membros da guilda: $e");
    } finally {
      if(mounted){
        setState(() { _isLoadingMembers = false; });
      }
    }
  }

  int _rolePriority(String role) {
    switch (role) {
      case 'Dono': return 0;
      case 'Vice-Dono': return 1;
      case 'Tesoureiro': return 2;
      case 'Membro': return 3;
      default: return 4;
    }
  }

  List<GuildMemberInfo> _getFilteredMembers() {
    List<GuildMemberInfo> filteredMembers = List.from(_guildMembersList);

    // Aplicar filtro de cargo
    if (_currentSort == 'cargo') {
      filteredMembers.sort((a, b) {
        int roleCompare = _rolePriority(a.role).compareTo(_rolePriority(b.role));
        if (roleCompare != 0) return roleCompare;
        return b.aura.compareTo(a.aura);
      });
    }

    // Aplicar filtro de aura
    if (_currentSort == 'aura') {
      filteredMembers.sort((a, b) {
        if (_isAscending) {
          return a.aura.compareTo(b.aura);
        } else {
          return b.aura.compareTo(a.aura);
        }
      });
    }

    return filteredMembers;
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Dono':
        return Colors.purple;
      case 'Vice-Dono':
        return Colors.blue;
      case 'Tesoureiro':
        return Colors.green;
      case 'Membro':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Dono':
        return Icons.star;
      case 'Vice-Dono':
        return Icons.star_half;
      case 'Tesoureiro':
        return Icons.account_balance_wallet;
      case 'Membro':
        return Icons.person;
      default:
        return Icons.person;
    }
  }

  IconData _getIconFromData(int iconData, String? fontFamily, String? fontPackage) {
    // Mapeamento de códigos comuns para ícones constantes do Material Design
    switch (iconData) {
      case 0xe148: return Icons.star; // star
      case 0xe153: return Icons.shield; // shield
      case 0xe85e: return Icons.group; // group
      case 0xe88e: return Icons.home; // home
      case 0xe7e9: return Icons.local_fire_department; // local_fire_department
      case 0xe869: return Icons.military_tech; // military_tech
      case 0xe8d2: return Icons.castle; // castle
      case 0xe86c: return Icons.favorite; // favorite
      case 0xe87c: return Icons.psychology; // psychology
      case 0xe1b2: return Icons.spa; // spa
      default: 
        // Para ícones não mapeados, usar um ícone padrão
        return Icons.groups;
    }
  }

  Future<void> _loadJoinRequests() async {
    if (_userGuildId == null) return;
    
    setState(() => _isLoadingRequests = true);
    
    try {
      QuerySnapshot requestsSnapshot = await FirebaseFirestore.instance
          .collection('guilds')
          .doc(_userGuildId)
          .collection('joinRequests')
          .where('status', isEqualTo: 'pending')
          .get();

      List<Map<String, dynamic>> requests = [];
      for (var doc in requestsSnapshot.docs) {
        Map<String, dynamic> requestData = doc.data() as Map<String, dynamic>;
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(requestData['userId'])
            .get();
            
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          requests.add({
            'requestId': doc.id,
            'userId': requestData['userId'],
            'userName': userData['playerName'] ?? 'Jogador Desconhecido',
            'userLevel': userData['level'] ?? 1,
            'userAura': _calculateUserAura(userData),
            'timestamp': requestData['timestamp'],
            'photoUrl': userData['profileImageUrl'],
          });
        }
      }
      
      setState(() {
        _joinRequests = requests;
        _isLoadingRequests = false;
      });
    } catch (e) {
      print("Erro ao carregar pedidos de entrada: $e");
      setState(() => _isLoadingRequests = false);
    }
  }

  int _calculateUserAura(Map<String, dynamic> userData) {
    Map<String, int> baseStats = Map<String, int>.from(userData['stats'] ?? {});
    Map<String, int> bonusStats = Map<String, int>.from(userData['bonusStats'] ?? {});
    String currentTitle = userData['title'] ?? 'Aspirante';
    String currentJob = userData['job'] ?? 'Nenhuma';
    int level = userData['level'] ?? 1;
    Map<String, bool> completedAchievements = Map<String, bool>.from(userData['completedAchievements'] ?? {});
    
    // Usar função centralizada para calcular aura
    return aura_utils.calculateTotalAura(
      baseStats: baseStats,
      bonusStats: bonusStats,
      currentTitle: currentTitle,
      currentJob: currentJob,
      level: level,
      completedAchievements: completedAchievements,
    );
  }

  Future<void> _handleJoinRequest(String requestId, String userId, bool accept) async {
    if (_userGuildId == null || _currentGuildDetails == null) return;
    
    setState(() => _isProcessingAction = true);
    
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      if (accept) {
        // Verificar limite de membros
        if (_currentGuildDetails!.memberCount >= 50) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("A guilda atingiu o limite máximo de 50 membros."), backgroundColor: Colors.red)
          );
          return;
        }

        // Adicionar membro à guilda
        Map<String, String> updatedMembers = Map<String, String>.from(_currentGuildDetails!.members);
        updatedMembers[userId] = "Membro";
        
        batch.update(
          FirebaseFirestore.instance.collection('guilds').doc(_userGuildId),
          {
            'members': updatedMembers,
            'memberCount': FieldValue.increment(1),
          }
        );
        
        // Atualizar dados do usuário
        batch.update(
          FirebaseFirestore.instance.collection('users').doc(userId),
          {
            'guildId': _userGuildId,
            'guildName': _currentGuildDetails!.name,
            'guildRole': "Membro",
          }
        );
      }
      
      // Atualizar status do pedido
      batch.update(
        FirebaseFirestore.instance.collection('guilds').doc(_userGuildId)
            .collection('joinRequests').doc(requestId),
        {'status': accept ? 'accepted' : 'rejected'}
      );
      
      await batch.commit();
      
      // Recarregar dados
      await _loadJoinRequests();
      await _checkUserGuildStatus();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? "Jogador aceito na guilda!" : "Pedido rejeitado."),
          backgroundColor: accept ? Colors.green : Colors.orange
        )
      );
    } catch (e) {
      print("Erro ao processar pedido de entrada: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao processar pedido."), backgroundColor: Colors.red)
      );
    } finally {
      setState(() => _isProcessingAction = false);
    }
  }

  Widget _buildJoinRequestsTab() {
    if (_isLoadingRequests) {
      return Center(child: CircularProgressIndicator(color: accentColorPurple));
    }

    if (_joinRequests.isEmpty) {
      return Center(
        child: Text(
          "Nenhum pedido de entrada pendente",
          style: TextStyle(color: textColor.withOpacity(0.7)),
        ),
      );
    }

    return ListView.builder(
      itemCount: _joinRequests.length,
      itemBuilder: (context, index) {
        final request = _joinRequests[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0.0),
          color: panelBgColor.withOpacity(0.6),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: accentColorBlue.withOpacity(0.3),
                      backgroundImage: request['photoUrl'] != null && request['photoUrl'].isNotEmpty
                          ? NetworkImage(request['photoUrl'])
                          : null,
                      child: request['photoUrl'] == null || request['photoUrl'].isEmpty
                          ? Icon(Icons.person, color: textColor.withOpacity(0.7), size: 25)
                          : null,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request['userName'],
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Nível ${request['userLevel']} • ',
                                style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
                              ),
                              Icon(Icons.whatshot_rounded, color: prColor, size: 12),
                              SizedBox(width: 2),
                              Text(
                                'Aura: ${request['userAura']}',
                                style: TextStyle(color: prColor, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isProcessingAction ? null : () => _handleJoinRequest(
                        request['requestId'],
                        request['userId'],
                        false
                      ),
                      child: Text("Recusar", style: TextStyle(color: Colors.red)),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isProcessingAction ? null : () => _handleJoinRequest(
                        request['requestId'],
                        request['userId'],
                        true
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text("Aceitar"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuildInfoView() {
    if (_currentGuildDetails == null) { return _buildNoGuildView(); }
    String userRole = _currentGuildDetails!.members[_currentUser?.uid] ?? "Membro";
    bool isOwner = userRole == "Dono";
    bool canManageDetails = isOwner;
    bool canInvite = isOwner || userRole == "Vice-Dono" || userRole == "Tesoureiro";
    bool canManageRequests = isOwner || userRole == "Vice-Dono";

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: accentColorBlue,
          unselectedLabelColor: textColor.withOpacity(0.7),
          indicatorColor: accentColorBlue,
          tabs: const [
            Tab(text: "Informações"),
            Tab(text: "Pedidos de Entrada"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Informações da Guilda
              RefreshIndicator(
                onRefresh: _checkUserGuildStatus,
                color: accentColorPurple,
                backgroundColor: primaryColor,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(radius: 50, backgroundColor: panelBgColor, child: Icon(_selectedGuildIcon, size: 50, color: accentColorBlue)),
                      SizedBox(height: 16),
                      Text(_currentGuildDetails!.name, style: TextStyle(color: accentColorBlue, fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      SizedBox(height: 8),
                      Text("Líder: ${_currentGuildDetails!.ownerName}", style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 15)),
                      SizedBox(height: 4),
                      Text("Membros: ${_currentGuildDetails!.memberCount} | Aura Total: ${_currentGuildDetails!.totalAura}", style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13)),
                      SizedBox(height: 12),
                      if (_currentGuildDetails!.description.isNotEmpty)
                        Padding(padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(_currentGuildDetails!.description, textAlign: TextAlign.center, style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 14, fontStyle: FontStyle.italic))),
                      Divider(color: accentColorBlue.withOpacity(0.3), height: 30),

                      // Botões de Ação da Guilda
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            if (canInvite)
                              Expanded(
                                child: _buildDialogButton(
                                  icon: Icons.person_add_alt_1_rounded,
                                  label: "Convidar",
                                  onPressed: _isProcessingAction ? null : _showInvitePlayerDialog,
                                  fullWidth: true,
                                ),
                              ),
                            if (canInvite && canManageDetails) SizedBox(width: 8),
                            if (canManageDetails)
                              Expanded(
                                child: _buildDialogButton(
                                  icon: Icons.edit_note_rounded,
                                  label: "Editar",
                                  onPressed: _isProcessingAction ? null : _showEditGuildDialog,
                                  fullWidth: true,
                                ),
                              ),
                            if ((canInvite || canManageDetails) && !isOwner) SizedBox(width: 8),
                            if (!isOwner)
                              Expanded(
                                child: _buildDialogButton(
                                  icon: Icons.exit_to_app_rounded,
                                  label: "Sair",
                                  onPressed: _isProcessingAction ? null : _leaveGuildConfirmation,
                                  color: Colors.orangeAccent[700],
                                  fullWidth: true,
                                ),
                              ),
                            if ((canInvite || canManageDetails || !isOwner) && isOwner) SizedBox(width: 8),
                            if (isOwner)
                              Expanded(
                                child: _buildDialogButton(
                                  icon: Icons.delete_forever_rounded,
                                  label: "Excluir",
                                  onPressed: _isProcessingAction ? null : _disbandGuildConfirmation,
                                  color: Colors.red[900],
                                  fullWidth: true,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Divider(color: accentColorBlue.withOpacity(0.3), height: 30),
                      Text("Membros da Guilda:", style: TextStyle(color: accentColorBlue, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      
                      // Botões de ordenação
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16.0,
                        runSpacing: 8.0,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(_currentSort == 'cargo' ? Icons.check : Icons.sort),
                            label: Text("Ordenar por Cargo"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _currentSort == 'cargo' ? accentColorPurple : panelBgColor,
                              foregroundColor: textColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _currentSort = 'cargo';
                                _isAscending = true;
                              });
                            },
                          ),
                          ElevatedButton.icon(
                            icon: Icon(_currentSort == 'aura' ? Icons.check : Icons.sort),
                            label: Text("Ordenar por Aura"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _currentSort == 'aura' ? accentColorPurple : panelBgColor,
                              foregroundColor: textColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _currentSort = 'aura';
                                _isAscending = !_isAscending;
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      _isLoadingMembers
                        ? Center(child: CircularProgressIndicator(color: accentColorPurple))
                        : _guildMembersList.isEmpty
                            ? Text("Nenhum membro encontrado.", style: TextStyle(color: textColor.withOpacity(0.7)))
                            : _buildMemberList(),
                    ],
                  ),
                ),
              ),
              // Tab 2: Pedidos de Entrada
              canManageRequests
                  ? _buildJoinRequestsTab()
                  : Center(
                      child: Text(
                        "Você não tem permissão para gerenciar pedidos de entrada",
                        style: TextStyle(color: textColor.withOpacity(0.7)),
                        textAlign: TextAlign.center,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoGuildView() {
    // Se não está em uma guilda, volta para a tela anterior automaticamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
    
    return Center(
      child: CircularProgressIndicator(color: accentColorPurple),
    );
  }

  Future<void> _leaveGuildConfirmation() async {
    if (!mounted) return;
    
    // Verificar se é o dono da guilda
    String userRole = _currentGuildDetails?.members[_currentUser?.uid] ?? "Membro";
    if (userRole == "Dono") {
      _showStyledDialog(
        passedContext: context,
        titleText: "Não é Possível Sair",
        icon: Icons.warning_outlined,
        iconColor: Colors.orange,
        contentWidgets: [
          Text("Como dono da guilda, você deve transferir a liderança para outro membro antes de sair.", style: TextStyle(color: textColor)),
        ],
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK", style: TextStyle(color: accentColorBlue)),
          ),
        ],
      );
      return;
    }

    final bool? confirmLeave = await _showStyledDialog<bool>(
      passedContext: context,
      titleText: "Sair da Guilda",
      icon: Icons.exit_to_app_rounded,
      iconColor: Colors.orangeAccent,
      contentWidgets: [
        Text("Tem certeza que deseja sair da guilda?", style: TextStyle(color: textColor)),
      ],
      actions: [
        TextButton(
          child: Text("Cancelar", style: TextStyle(color: textColor.withOpacity(0.7))),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.white,
          ),
          child: Text("Sair"),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );

    if (confirmLeave == true) {
      _leaveGuild();
    }
  }

  Future<void> _leaveGuild() async {
    if (_currentUser == null || _userGuildId == null || !mounted) return;

    setState(() { _isProcessingAction = true; });

    DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(_currentUser.uid);
    DocumentReference guildDocRef = FirebaseFirestore.instance.collection('guilds').doc(_userGuildId!);
    WriteBatch batch = FirebaseFirestore.instance.batch();

    try {
      // Não precisamos mais dos dados do usuário já que não calculamos aura

      // 1. Remover membro do mapa 'members' da guilda
      batch.update(guildDocRef, {'members.${_currentUser.uid}': FieldValue.delete()});
      // 2. Decrementar apenas memberCount (aura total será calculada dinamicamente)
      batch.update(guildDocRef, {
        'memberCount': FieldValue.increment(-1),
        // 'totalAura': FieldValue.increment(-userAura), // Removido para evitar problemas de permissão
      });
      // 3. Limpar dados da guilda no documento do usuário
      batch.update(userDocRef, {
        'guildId': null,
        'guildName': null,
        'guildRole': null,
      });

      await batch.commit();

      if (mounted) {
        _showStyledDialog(
          passedContext: context,
          titleText: "Sucesso",
          icon: Icons.check_circle_outline,
          iconColor: Colors.greenAccent,
          contentWidgets: [
            Text("Você saiu da guilda.", style: TextStyle(color: textColor))
          ],
          actions: [
            _buildDialogButton(
              icon: Icons.check,
              label: "OK",
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _userGuildId = null;
                  _currentGuildDetails = null;
                  _guildMembersList = [];
                  _isProcessingAction = false;
                });
              }
            )
          ]
        );
      }
    } catch (e) {
      print("Erro ao sair da guilda: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao sair da guilda. Tente novamente."), backgroundColor: Colors.redAccent)
        );
        setState(() { _isProcessingAction = false; });
      }
    }
  }

  Future<void> _disbandGuildConfirmation() async {
    if (!mounted) return;
    final bool? confirmDisband = await _showStyledDialog<bool>(
      passedContext: context,
      titleText: "Excluir Guilda",
      icon: Icons.delete_forever_rounded,
      iconColor: Colors.red,
      contentWidgets: [
        Text("Tem certeza que deseja excluir a guilda? Esta ação não pode ser desfeita.", style: TextStyle(color: textColor)),
      ],
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text("Excluir"),
          onPressed: () => Navigator.of(context).pop(true),
        ),
        TextButton(
          child: Text("Cancelar", style: TextStyle(color: textColor.withOpacity(0.7))),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );

    if (confirmDisband == true) {
      _disbandGuild();
    }
  }

  Future<void> _disbandGuild() async {
    if (_currentUser == null || _userGuildId == null || _currentGuildDetails == null || !mounted) return;
    if (_currentGuildDetails!.ownerId != _currentUser.uid) return; // Segurança extra

    setState(() { _isProcessingAction = true; });

    try {
      // 1. 🔧 CORREÇÃO: Deletar apenas o documento da guilda
      // Os usuários serão notificados e limparão seus próprios dados posteriormente
      DocumentReference guildDocRef = FirebaseFirestore.instance.collection('guilds').doc(_userGuildId!);
      await guildDocRef.delete();

      // Salvar o nome da guilda antes de limpar os dados
      String guildName = _currentGuildDetails!.name;

      // 2. Limpar apenas os dados do PRÓPRIO usuário (dono)
      await FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).update({
        'guildId': null,
        'guildName': null,
        'guildRole': null,
      });

      if (mounted) {
        _showStyledDialog(
          passedContext: context,
          titleText: "Guilda Excluída",
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
          contentWidgets: [
            Text("Guilda '$guildName' excluída com sucesso.", style: TextStyle(color: textColor)),
          ],
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK", style: TextStyle(color: accentColorBlue)),
            ),
          ],
        );
        
        setState(() {
          _userGuildId = null;
          _currentGuildDetails = null;
          _guildMembersList = [];
          _isProcessingAction = false;
        });
         // Cancelar o listener da guilda após a exclusão
        _guildListenerSubscription?.cancel();
        _guildListenerSubscription = null;
      }
    } catch (e) {
      print("Erro ao excluir guilda: $e");
      if (mounted) {
        _showStyledDialog(
          passedContext: context,
          titleText: "Erro",
          icon: Icons.error_outline,
          iconColor: Colors.red,
          contentWidgets: [
            Text("Erro ao excluir guilda. Tente novamente.", style: TextStyle(color: textColor)),
          ],
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK", style: TextStyle(color: accentColorBlue)),
            ),
          ],
        );
        setState(() { _isProcessingAction = false; });
      }
    }
  }

  // --- NOVAS FUNÇÕES PARA GERENCIAMENTO DA GUILDA ---

  void _showInvitePlayerDialog() {
    _invitePlayerNameController.clear();
    _showStyledDialog<void>(
      passedContext: context,
      titleText: "Convidar Jogador",
      icon: Icons.person_add_alt_1_rounded,
      iconColor: accentColorBlue,
      contentWidgets: [
        Text("Digite o nome exato do jogador que deseja convidar:", style: TextStyle(color: textColor.withOpacity(0.8))),
        SizedBox(height: 10),
        TextField(
          controller: _invitePlayerNameController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: "Nome do Jogador",
            labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColorBlue.withOpacity(0.5))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColorPurple)),
          ),
        ),
      ],
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text("Cancelar", style: TextStyle(color: textColor.withOpacity(0.7))),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _sendGuildInvitation();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColorPurple,
            foregroundColor: Colors.white,
          ),
          child: Text("Convidar"),
        ),
      ],
    );
  }

  // Função para mostrar diálogo de edição da guilda
  void _showEditGuildDialog() {
    _guildNameController.text = _currentGuildDetails?.name ?? '';
    _guildDescriptionController.text = _currentGuildDetails?.description ?? '';
    
    _showStyledDialog(
      passedContext: context,
      titleText: "Editar Guilda",
      icon: Icons.edit_note_rounded,
      iconColor: accentColorBlue,
      contentWidgets: [
        TextField(
          controller: _guildNameController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: "Nome da Guilda",
            labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColorBlue.withOpacity(0.5))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColorPurple)),
          ),
          maxLength: 30,
        ),
        SizedBox(height: 10),
        TextField(
          controller: _guildDescriptionController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: "Descrição",
            labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColorBlue.withOpacity(0.5))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColorPurple)),
          ),
          maxLines: 3,
          maxLength: 150,
        ),
      ],
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text("Cancelar", style: TextStyle(color: textColor.withOpacity(0.7))),
        ),
        ElevatedButton(
          onPressed: _isProcessingAction ? null : () {
            Navigator.of(context).pop();
            _updateGuildDetails();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColorPurple,
            foregroundColor: Colors.white,
          ),
          child: _isProcessingAction 
            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text("Salvar"),
        ),
      ],
    );
  }

  // Função para atualizar detalhes da guilda
  Future<void> _updateGuildDetails() async {
    if (_currentUser == null || _userGuildId == null || _currentGuildDetails == null) return;
    
    String newName = _guildNameController.text.trim();
    String newDescription = _guildDescriptionController.text.trim();
    
    if (newName.isEmpty) {
      _showStyledDialog(
        passedContext: context,
        titleText: "Campo Obrigatório",
        icon: Icons.warning_outlined,
        iconColor: Colors.orange,
        contentWidgets: [
          Text("Nome da guilda não pode estar vazio.", style: TextStyle(color: textColor)),
        ],
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK", style: TextStyle(color: accentColorBlue)),
          ),
        ],
      );
      return;
    }

    setState(() { _isProcessingAction = true; });

    try {
      // Verificar se já existe outra guilda com o mesmo nome (exceto a atual)
      if (newName != _currentGuildDetails!.name) {
        QuerySnapshot existingGuilds = await FirebaseFirestore.instance
            .collection('guilds')
            .where('name', isEqualTo: newName)
            .get();

        if (existingGuilds.docs.isNotEmpty) {
          _showStyledDialog(
            passedContext: context,
            titleText: "Nome Indisponível",
            icon: Icons.warning_outlined,
            iconColor: Colors.orange,
            contentWidgets: [
              Text("Já existe uma guilda com este nome.", style: TextStyle(color: textColor)),
            ],
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("OK", style: TextStyle(color: accentColorBlue)),
              ),
            ],
          );
          return;
        }
      }

      // Atualizar dados da guilda
      await FirebaseFirestore.instance.collection('guilds').doc(_userGuildId!).update({
        'name': newName,
        'description': newDescription.isEmpty ? 'Nenhuma descrição definida.' : newDescription,
      });

      // Atualizar nome da guilda em todos os membros
      if (newName != _currentGuildDetails!.name) {
        WriteBatch batch = FirebaseFirestore.instance.batch();
        for (String memberUid in _currentGuildDetails!.members.keys) {
          DocumentReference memberRef = FirebaseFirestore.instance.collection('users').doc(memberUid);
          batch.update(memberRef, {'guildName': newName});
        }
        await batch.commit();
      }

      _showStyledDialog(
        passedContext: context,
        titleText: "Sucesso",
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
        contentWidgets: [
          Text("Guilda atualizada com sucesso!", style: TextStyle(color: textColor)),
        ],
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK", style: TextStyle(color: accentColorBlue)),
          ),
        ],
      );

      // Recarregar dados da guilda
      await _checkUserGuildStatus();

    } catch (e) {
      print("Erro ao atualizar guilda: $e");
      _showStyledDialog(
        passedContext: context,
        titleText: "Erro",
        icon: Icons.error_outline,
        iconColor: Colors.red,
        contentWidgets: [
          Text("Erro ao atualizar guilda. Tente novamente.", style: TextStyle(color: textColor)),
        ],
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK", style: TextStyle(color: accentColorBlue)),
          ),
        ],
      );
    } finally {
      if (mounted) setState(() { _isProcessingAction = false; });
    }
  }

  Future<void> _sendGuildInvitation() async {
    if (_currentUser == null || _userGuildId == null || _currentGuildDetails == null || !mounted) return;
    String targetPlayerName = _invitePlayerNameController.text.trim();
    if (targetPlayerName.isEmpty) {
      if (!mounted) return;
      _showStyledDialog(
        passedContext: context,
        titleText: "Campo Obrigatório",
        icon: Icons.warning_outlined,
        iconColor: Colors.orange,
        contentWidgets: [
          Text("Nome do jogador não pode estar vazio.", style: TextStyle(color: textColor)),
        ],
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK", style: TextStyle(color: accentColorBlue)),
          ),
        ],
      );
      return;
    }

    // VERIFICAÇÃO DO LIMITE DE MEMBROS DA GUILDA ATUAL
    if ((_currentGuildDetails!.memberCount) >= 50) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Sua guilda atingiu o limite máximo de 50 membros."),
        backgroundColor: yellowWarningColor
      ));
      return;
    }

    setState(() { _isProcessingAction = true; });

    try {
      // 1. Encontrar o UID do jogador pelo nome
      QuerySnapshot playerQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('playerName', isEqualTo: targetPlayerName)
          .limit(1)
          .get();

      if (playerQuery.docs.isEmpty) {
        if (!mounted) return;
        _showStyledDialog(
          passedContext: context,
          titleText: "Jogador Não Encontrado",
          icon: Icons.person_off_outlined,
          iconColor: Colors.red,
          contentWidgets: [
            Text("Jogador '$targetPlayerName' não encontrado.", style: TextStyle(color: textColor)),
          ],
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK", style: TextStyle(color: accentColorBlue)),
            ),
          ],
        );
        setState(() { _isProcessingAction = false; });
        return;
      }
      String targetUserId = playerQuery.docs.first.id;
      Map<String, dynamic> targetUserData = playerQuery.docs.first.data() as Map<String, dynamic>;

      if (targetUserId == _currentUser.uid) {
        if (!mounted) return;
        _showStyledDialog(
          passedContext: context,
          titleText: "Convite Inválido",
          icon: Icons.warning_outlined,
          iconColor: Colors.orange,
          contentWidgets: [
            Text("Você não pode convidar a si mesmo.", style: TextStyle(color: textColor)),
          ],
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK", style: TextStyle(color: accentColorBlue)),
            ),
          ],
        );
        setState(() { _isProcessingAction = false; });
        return;
      }

      if (targetUserData['guildId'] != null) {
        if (!mounted) return;
        _showStyledDialog(
          passedContext: context,
          titleText: "Jogador Indisponível",
          icon: Icons.info_outline,
          iconColor: Colors.orange,
          contentWidgets: [
            Text("$targetPlayerName já está em uma guilda.", style: TextStyle(color: textColor)),
          ],
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK", style: TextStyle(color: accentColorBlue)),
            ),
          ],
        );
        setState(() { _isProcessingAction = false; });
        return;
      }

      // Buscar dados do usuário atual para obter o playerName
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .get();
      
      Map<String, dynamic> currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      String inviterName = currentUserData['playerName'] ?? _currentUser.displayName ?? _currentUser.email ?? 'Jogador';

      // 2. Criar o convite na subcoleção do jogador alvo
      await FirebaseFirestore.instance
          .collection('users').doc(targetUserId)
          .collection('guildInvitations')
          .doc(_userGuildId)
          .set({
        'guildId': _userGuildId,
        'guildName': _currentGuildDetails!.name,
        'inviterName': inviterName,
        'inviterId': _currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (!mounted) return;
      _showStyledDialog(
        passedContext: context,
        titleText: "Convite Enviado",
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
        contentWidgets: [
          Text("Convite enviado para $targetPlayerName!", style: TextStyle(color: textColor)),
        ],
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK", style: TextStyle(color: accentColorBlue)),
          ),
        ],
      );
    } catch (e) {
      print("Erro ao enviar convite de guilda: $e");
      if (!mounted) return;
      _showStyledDialog(
        passedContext: context,
        titleText: "Erro",
        icon: Icons.error_outline,
        iconColor: Colors.red,
        contentWidgets: [
          Text("Falha ao enviar convite.", style: TextStyle(color: textColor)),
        ],
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK", style: TextStyle(color: accentColorBlue)),
          ),
        ],
      );
    } finally {
      if (mounted) setState(() { _isProcessingAction = false; });
    }
  }

  void _showMemberOptions(GuildMemberInfo member) {
    List<Widget> memberActions = [];

    // Promover a Vice-Dono
    if (_currentGuildDetails?.ownerId != member.uid && (member.role == "Membro" || member.role == "Tesoureiro")) {
      memberActions.add(
        ListTile(
          leading: Icon(Icons.star, color: Colors.blue),
          title: Text("Promover a Vice-Dono", style: TextStyle(color: textColor)),
          onTap: () {
            Navigator.pop(context);
            _promoteMember(member, "Vice-Dono");
          },
        ),
      );
    }

    // Promover a Tesoureiro
    if (_currentGuildDetails?.ownerId != member.uid && member.role == "Membro") {
      memberActions.add(
        ListTile(
          leading: Icon(Icons.account_balance_wallet, color: Colors.green),
          title: Text("Promover a Tesoureiro", style: TextStyle(color: textColor)),
          onTap: () {
            Navigator.pop(context);
            _promoteMember(member, "Tesoureiro");
          },
        ),
      );
    }

    // Rebaixar para Membro
    if (_currentGuildDetails?.ownerId != member.uid && (member.role == "Vice-Dono" || member.role == "Tesoureiro")) {
      memberActions.add(
        ListTile(
          leading: Icon(Icons.arrow_downward, color: Colors.orange),
          title: Text("Rebaixar para Membro", style: TextStyle(color: textColor)),
          onTap: () {
            Navigator.pop(context);
            _promoteMember(member, "Membro");
          },
        ),
      );
    }

    // Expulsar da Guilda
    if (_currentGuildDetails?.ownerId != member.uid) {
      memberActions.add(
        ListTile(
          leading: Icon(Icons.exit_to_app, color: Colors.red),
          title: Text("Expulsar da Guilda", style: TextStyle(color: Colors.red)),
          onTap: () {
            Navigator.pop(context);
            _confirmKickMember(member);
          },
        ),
      );
    }

    if (memberActions.isEmpty) {
      memberActions.add(
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Nenhuma ação disponível para este membro.",
            style: TextStyle(color: textColor.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    _showStyledDialog(
      passedContext: context,
      titleText: "Opções do Membro",
      icon: Icons.person_outline,
      iconColor: accentColorBlue,
      contentWidgets: [
        Text(
          "Membro: ${member.name}",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        ...memberActions,
      ],
      actions: [
        _buildDialogButton(
          icon: Icons.close,
          label: "Cancelar",
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Future<void> _promoteMember(GuildMemberInfo member, String newRole) async {
    if (_currentGuildDetails == null || _currentUser == null) return;
    
    // Verificar se o usuário atual tem permissão para promover
    String? currentUserRole = _currentGuildDetails!.members[_currentUser.uid];
    if (currentUserRole == null || !['Dono', 'Vice-Dono'].contains(currentUserRole)) {
      if (mounted) {
        _showStyledDialog(
          passedContext: context,
          titleText: "Sem Permissão",
          icon: Icons.warning_outlined,
          iconColor: Colors.red,
          contentWidgets: [
            Text("Você não tem permissão para promover membros.", style: TextStyle(color: textColor)),
          ],
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK", style: TextStyle(color: accentColorBlue)),
            ),
          ],
        );
      }
      return;
    }

    // Verificar se o membro já possui este cargo
    if (member.role == newRole) {
      if (mounted) {
        _showStyledDialog(
          passedContext: context,
          titleText: "Cargo Duplicado",
          icon: Icons.info_outline,
          iconColor: Colors.orange,
          contentWidgets: [
            Text("${member.name} já possui o cargo de $newRole.", style: TextStyle(color: textColor)),
          ],
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK", style: TextStyle(color: accentColorBlue)),
            ),
          ],
        );
      }
      return;
    }
    
    setState(() => _isProcessingAction = true);
    
    try {
      // Criar um convite de cargo na coleção global
      await FirebaseFirestore.instance
          .collection('guildRoleInvites')
          .add({
        'guildId': _currentGuildDetails!.id,
        'guildName': _currentGuildDetails!.name,
        'targetUserId': member.uid,
        'targetUserName': member.name,
        'newRole': newRole,
        'currentRole': member.role,
        'invitedBy': _currentUser.uid,
        'inviterName': _currentUser.displayName ?? 'Administrador',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Atualizar o cargo na guilda (o membro precisa aceitar para atualizar seu documento pessoal)
      Map<String, String> updatedMembers = Map<String, String>.from(_currentGuildDetails!.members);
      updatedMembers[member.uid] = newRole;
      
      await FirebaseFirestore.instance
          .collection('guilds')
          .doc(_currentGuildDetails!.id)
          .update({'members': updatedMembers});
      
      // Atualizar o estado local
      if (!mounted) return;
      setState(() {
        _currentGuildDetails = Guild(
          id: _currentGuildDetails!.id,
          name: _currentGuildDetails!.name,
          description: _currentGuildDetails!.description,
          ownerId: _currentGuildDetails!.ownerId,
          ownerName: _currentGuildDetails!.ownerName,
          members: updatedMembers,
          memberCount: _currentGuildDetails!.memberCount,
          totalAura: _currentGuildDetails!.totalAura,
          createdAt: _currentGuildDetails!.createdAt,
          iconData: _currentGuildDetails!.iconData,
          iconFontFamily: _currentGuildDetails!.iconFontFamily,
          iconFontPackage: _currentGuildDetails!.iconFontPackage,
        );
      });
      
      // Recarregar lista de membros para refletir as mudanças
      await _fetchGuildMembers(_currentGuildDetails!.id, updatedMembers);
      
      if (!mounted) return;
      _showStyledDialog(
        passedContext: context,
        titleText: "Convite Enviado",
        icon: Icons.mail_outline,
        iconColor: Colors.green,
        contentWidgets: [
          Text("Convite de cargo enviado para ${member.name}!", style: TextStyle(color: textColor)),
          SizedBox(height: 8),
          Text("O cargo será efetivado quando o convite for aceito.", style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12)),
        ],
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK", style: TextStyle(color: accentColorBlue)),
          ),
        ],
      );
    } catch (e) {
      print("Erro ao enviar convite de cargo: $e");
      if (!mounted) return;
      _showStyledDialog(
        passedContext: context,
        titleText: "Erro",
        icon: Icons.error_outline,
        iconColor: Colors.red,
        contentWidgets: [
          Text("Erro ao enviar convite de cargo.", style: TextStyle(color: textColor)),
        ],
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK", style: TextStyle(color: accentColorBlue)),
          ),
        ],
      );
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  void _confirmKickMember(GuildMemberInfo member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: panelBgColor,
        title: Text("Confirmar Expulsão", style: TextStyle(color: textColor)),
        content: Text(
          "Tem certeza que deseja expulsar ${member.name} da guilda?",
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar", style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _kickMember(member);
            },
            child: Text("Confirmar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _kickMember(GuildMemberInfo member) async {
    if (_currentGuildDetails == null || _currentUser == null) return;

    // Impedir que o dono da guilda seja expulso
    if (member.uid == _currentGuildDetails!.ownerId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("O dono da guilda não pode ser expulso."), backgroundColor: Colors.red)
      );
      return;
    }
    
    setState(() => _isProcessingAction = true);
    
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // Remover o membro da guilda
      Map<String, String> updatedMembers = Map<String, String>.from(_currentGuildDetails!.members);
      updatedMembers.remove(member.uid);
      
      // Atualizar o documento da guilda
      batch.update(
        FirebaseFirestore.instance.collection('guilds').doc(_currentGuildDetails!.id),
        {
          'members': updatedMembers,
          'memberCount': FieldValue.increment(-1),
        },
      );
      
      // Atualizar o documento do usuário
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(member.uid),
        {
          'guildId': FieldValue.delete(),
          'guildName': FieldValue.delete(),
          'guildRole': FieldValue.delete(),
        },
      );
      
      await batch.commit();
      
      // Recarregar lista de membros para refletir as mudanças
      await _fetchGuildMembers(_currentGuildDetails!.id, updatedMembers);
      
      // Atualizar o estado local
      if (!mounted) return;
      setState(() {
        _currentGuildDetails = Guild(
          id: _currentGuildDetails!.id,
          name: _currentGuildDetails!.name,
          description: _currentGuildDetails!.description,
          ownerId: _currentGuildDetails!.ownerId,
          ownerName: _currentGuildDetails!.ownerName,
          members: updatedMembers,
          memberCount: _currentGuildDetails!.memberCount - 1,
          totalAura: _currentGuildDetails!.totalAura,
          createdAt: _currentGuildDetails!.createdAt,
          iconData: _currentGuildDetails!.iconData,
          iconFontFamily: _currentGuildDetails!.iconFontFamily,
          iconFontPackage: _currentGuildDetails!.iconFontPackage,
        );
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Membro expulso com sucesso!"), backgroundColor: Colors.green)
      );
    } catch (e) {
      print("Erro ao expulsar membro: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao expulsar membro."), backgroundColor: Colors.red)
      );
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  Widget _buildMemberList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _getFilteredMembers().length,
      itemBuilder: (context, index) {
        final member = _getFilteredMembers()[index];
        final isOwner = _currentUser?.uid == member.uid;
        final myRolePriority = _currentGuildDetails != null 
            ? _rolePriority(_currentGuildDetails!.members[_currentUser!.uid] ?? "Membro")
            : 99; // Prioridade alta para não poder gerenciar
        final memberRolePriority = _rolePriority(member.role);
        // Apenas dono e vice-dono podem gerenciar outros membros
        // Usuários não podem gerenciar a si mesmos (exceto dono da guilda)
        final canManageMember = (myRolePriority <= 1) && // Apenas Dono (0) e Vice-Dono (1)
                               (myRolePriority < memberRolePriority || 
                                (_currentGuildDetails!.ownerId == _currentUser!.uid && isOwner));

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0.0),
          color: panelBgColor.withOpacity(0.6),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: InkWell(
            onTap: canManageMember ? () => _showMemberOptions(member) : null,
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Foto de perfil do membro
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: accentColorBlue.withOpacity(0.3),
                    backgroundImage: member.photoUrl != null && member.photoUrl!.isNotEmpty
                        ? NetworkImage(member.photoUrl!)
                        : null,
                    child: member.photoUrl == null || member.photoUrl!.isEmpty
                        ? Icon(Icons.person, color: textColor.withOpacity(0.7), size: 25)
                        : null,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            // Icone e nome do cargo
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getRoleColor(member.role).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_getRoleIcon(member.role), size: 14, color: textColor),
                                  SizedBox(width: 4),
                                  Text(
                                    member.role,
                                    style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            Row(
                              children: [
                                Text(
                                  'Nível ${member.level} • ',
                                  style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
                                ),
                                Icon(Icons.whatshot_rounded, color: prColor, size: 12),
                                SizedBox(width: 2),
                                Text(
                                  'Aura: ${member.aura}',
                                  style: TextStyle(color: prColor, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (canManageMember)
                    Icon(Icons.arrow_forward_ios, color: textColor.withOpacity(0.5), size: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: Text("Guilda", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: accentColorBlue),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColorPurple))
          : _userGuildId != null && _currentGuildDetails != null
              ? _buildGuildInfoView()
              : _buildNoGuildView(),
    );
  }
}