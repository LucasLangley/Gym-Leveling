// Em lib/screens/social_screen.dart
// ignore_for_file: prefer_const_constructors, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../utils/aura_calculator.dart' as aura_utils;
import 'dart:async';
import 'friend_requests_screen.dart'; // Para navegar para a tela de pedidos de amizade
import 'my_friends_screen.dart'; // Importando a nova tela
import 'guild_management_screen.dart'; // Importando a nova tela de gerenciamento de guilda
import 'guild_invitations_screen.dart'; // Importando a tela de convites de guilda
import 'view_other_profile_screen.dart';
import '../l10n/app_localizations.dart';
// import 'guild_screen.dart'; // Futuramente, para a tela de guildas

// Cores
const Color primaryColor = Color(0xFF0A0E21);
const Color accentColorBlue = Color(0xFF40C4FF);
const Color accentColorPurple = Color(0xFF8A2BE2);
const Color textColor = Colors.white;
const Color panelBgColor = Color(0x991D1E33);
const Color prColor = Colors.amberAccent; 

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final _logger = Logger();
  final TextEditingController _searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  bool _hasGuildRoleInvite = false;
  bool _isSearching = false;
  List<Map<String, dynamic>> _friendsList = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isProcessingGuildCreation = false;
  String? _userGuildId;
  StreamSubscription? _friendRequestSubscription;

  // Controladores para criação de guilda
  final TextEditingController _guildNameController = TextEditingController();
  final TextEditingController _guildDescriptionController = TextEditingController();
  IconData _selectedGuildIcon = Icons.shield_outlined;

  // Lista de ícones disponíveis para guildas
  final List<IconData> _availableGuildIcons = [
    Icons.shield_outlined,
    Icons.castle_outlined,
    Icons.security_outlined,
    Icons.star_border_outlined,
    Icons.military_tech_outlined,
    Icons.diamond_outlined,
    Icons.flash_on_outlined,
    Icons.local_fire_department_outlined,
    Icons.pets_outlined,
    Icons.nature_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _checkGuildRoleInvites();
    _checkUserGuildStatus();
    _checkGuildInvites();
    _listenToFriendRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _guildNameController.dispose();
    _guildDescriptionController.dispose();
    _friendRequestSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkUserGuildStatus() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _userGuildId = userData['guildId'] as String?;
        });
      }
    } catch (e) {
      _logger.e('Erro ao verificar status da guilda do usuário', error: e);
    }
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('friends')
          .get();

      List<Map<String, dynamic>> friends = [];
      for (var doc in friendsSnapshot.docs) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(doc.id)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          friends.add({
            'id': doc.id,
            'name': userData['playerName'] ?? 'Jogador Desconhecido',
            'level': userData['level'] ?? 1,
            'aura': _calculateAura(userData),
            'profileImageUrl': userData['profileImageUrl'] as String?,
          });
        }
      }

      // Ordenar amigos por nível e aura
      friends.sort((a, b) {
        if (a['aura'] != b['aura']) {
          return b['aura'].compareTo(a['aura']);
        }
        return b['level'].compareTo(a['level']);
      });

      setState(() {
        _friendsList = friends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkGuildRoleInvites() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      QuerySnapshot roleInvites = await FirebaseFirestore.instance
          .collection('guildRoleInvites')
          .where('targetUserId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (mounted) {
        setState(() {
          _hasGuildRoleInvite = roleInvites.docs.isNotEmpty;
        });

        // Se há convites pendentes, mostrar o dialog
        if (roleInvites.docs.isNotEmpty) {
          _showGuildRoleInvitesDialog(roleInvites.docs);
        }
      }
    } catch (e) {
      _logger.e('Erro ao verificar convites para cargo', error: e);
    }
  }

  void _showGuildRoleInvitesDialog(List<QueryDocumentSnapshot> inviteDocs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
          child: Row(
            children: const [
              Icon(Icons.military_tech, color: Colors.amber),
              SizedBox(width: 10),
              Text(
                "CONVITES DE CARGO",
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: inviteDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                color: panelBgColor.withOpacity(0.7),
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Guilda: ${data['guildName'] ?? 'Desconhecida'}",
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Novo cargo: ${data['newRole'] ?? 'Desconhecido'}",
                        style: TextStyle(color: accentColorBlue),
                      ),
                      Text(
                        "Convidado por: ${data['inviterName'] ?? 'Desconhecido'}",
                        style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _acceptRoleInvite(doc),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: Text("Aceitar"),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _declineRoleInvite(doc),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: Text("Recusar"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Fechar", style: TextStyle(color: accentColorBlue)),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRoleInvite(QueryDocumentSnapshot inviteDoc) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final data = inviteDoc.data() as Map<String, dynamic>;
      
      // Atualizar o cargo do usuário em seu documento
      String newRole = data['newRole'] as String? ?? 'Membro';
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'guildRole': newRole});

      // Deletar o convite da coleção global
      await inviteDoc.reference.delete();

      if (mounted) {
        _showStyledDialog(
          titleText: "Sucesso",
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
          contentWidgets: [
            Text("Cargo atualizado para $newRole!", style: TextStyle(color: textColor)),
          ],
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text("OK"),
            ),
          ],
        );
        
        // Fechar o dialog e recarregar
        Navigator.of(context).pop();
        _checkUserGuildStatus();
        _checkGuildRoleInvites();
      }
    } catch (e) {
      _logger.e("Erro ao aceitar convite de cargo", error: e);
      if (mounted) {
        _showStyledDialog(
          titleText: "Erro",
          icon: Icons.error_outline,
          iconColor: Colors.red,
          contentWidgets: [
            Text("Erro ao aceitar convite de cargo.", style: TextStyle(color: textColor)),
          ],
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text("OK"),
            ),
          ],
        );
      }
    }
  }

  Future<void> _declineRoleInvite(QueryDocumentSnapshot inviteDoc) async {
    try {
      final data = inviteDoc.data() as Map<String, dynamic>;
      
      // Reverter o cargo na guilda se foi alterado prematuramente
      String? guildId = data['guildId'] as String?;
      String? targetUserId = data['targetUserId'] as String?;
      
      if (guildId != null && targetUserId != null) {
        DocumentSnapshot guildDoc = await FirebaseFirestore.instance
            .collection('guilds')
            .doc(guildId)
            .get();
            
        if (guildDoc.exists) {
          Map<String, dynamic> guildData = guildDoc.data() as Map<String, dynamic>;
          Map<String, String> members = Map<String, String>.from(guildData['members'] ?? {});
          
          // Reverter para o cargo anterior
          String targetUserId = data['targetUserId'] as String? ?? '';
          String currentRole = data['currentRole'] as String? ?? 'Membro';
          if (members.containsKey(targetUserId)) {
            members[targetUserId] = currentRole;
            
            await FirebaseFirestore.instance
                .collection('guilds')
                .doc(guildId)
                .update({'members': members});
          }
        }
      }
      
      await inviteDoc.reference.delete();

      if (mounted) {
        _showStyledDialog(
          titleText: "Convite Recusado",
          icon: Icons.info_outline,
          iconColor: Colors.orange,
          contentWidgets: [
            Text("Convite de cargo recusado.", style: TextStyle(color: textColor)),
          ],
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text("OK"),
            ),
          ],
        );
        
        // Fechar o dialog se não há mais convites
        Navigator.of(context).pop();
        _checkGuildRoleInvites(); // Verificar se há mais convites
      }
    } catch (e) {
      _logger.e("Erro ao recusar convite de cargo", error: e);
      if (mounted) {
        _showStyledDialog(
          titleText: "Erro",
          icon: Icons.error_outline,
          iconColor: Colors.red,
          contentWidgets: [
            Text("Erro ao recusar convite de cargo.", style: TextStyle(color: textColor)),
          ],
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text("OK"),
            ),
          ],
        );
      }
    }
  }

  int _calculateAura(Map<String, dynamic> userData) {
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

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Buscar jogadores
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('playerName', isGreaterThanOrEqualTo: query)
          .where('playerName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(10)
          .get();

      List<Map<String, dynamic>> results = [];
      for (var doc in usersSnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        results.add({
          'id': doc.id,
          'name': userData['playerName'] ?? 'Jogador Desconhecido',
          'level': userData['level'] ?? 1,
          'profileImageUrl': userData['profileImageUrl'] as String?,
        });
      }

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      _logger.e('Erro ao realizar busca', error: e);
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Widget _buildSearchSection() {
    return Container(
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          // Campo de busca de jogadores
          TextField(
            controller: _searchController,
            onChanged: _performSearch,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Buscar jogadores...',
              hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
              prefixIcon: Icon(Icons.search, color: accentColorBlue),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: accentColorBlue),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: primaryColor.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColorBlue.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColorBlue.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColorBlue),
              ),
            ),
          ),
          // Resultados da busca
          if (_isSearching)
            Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: accentColorPurple),
            )
          else if (_searchResults.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColorBlue.withOpacity(0.3)),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: accentColorBlue.withOpacity(0.3),
                      backgroundImage: result['profileImageUrl'] != null
                          ? NetworkImage(result['profileImageUrl'])
                          : null,
                      child: result['profileImageUrl'] == null
                          ? Icon(Icons.person, color: textColor.withOpacity(0.7))
                          : null,
                    ),
                    title: Text(
                      result['name'],
                      style: TextStyle(color: textColor),
                    ),
                    subtitle: Text(
                      'Nível ${result['level']}',
                      style: TextStyle(color: textColor.withOpacity(0.7)),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewOtherProfileScreen(
                            userId: result['id'],
                            initialPlayerName: result['name'],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? iconColor,
    Color? backgroundColor,
    bool showBadge = false,
  }) {
    return Stack(
      children: [
        ElevatedButton.icon(
          icon: Icon(icon, size: 24, color: iconColor ?? accentColorBlue),
          label: Text(label, style: TextStyle(fontSize: 14, color: textColor)),
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? accentColorPurple.withOpacity(0.8),
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            minimumSize: Size.fromHeight(50),
          ),
          onPressed: onPressed,
        ),
        if (showBadge)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
      ],
    );
  }

  // Função para lidar com o clique no botão Guilda
  void _handleGuildButtonPressed() {
    if (_userGuildId != null) {
      // Usuário já está em uma guilda - navegar para guild_management_screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GuildManagementScreen()),
      ).then((_) {
        // Atualizar status da guilda quando voltar
        _checkUserGuildStatus();
        _checkGuildRoleInvites();
      });
    } else {
      // Usuário não está em uma guilda - mostrar diálogo de criação
      _showCreateGuildDialog();
    }
  }

  // Função para mostrar diálogos estilizados
  Future<T?> _showStyledDialog<T>({
    required String titleText,
    required List<Widget> contentWidgets,
    required List<Widget> actions,
    IconData icon = Icons.info_outline,
    Color iconColor = accentColorBlue,
  }) {
    return showDialog<T>(
      context: context,
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

  // Função para mostrar diálogo de criação de guilda
  void _showCreateGuildDialog() {
    _guildNameController.clear();
    _guildDescriptionController.clear();
    _selectedGuildIcon = Icons.shield_outlined;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: accentColorBlue),
                    SizedBox(width: 10),
                    Text(AppLocalizations.of(context)!.createNewGuild, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Campo nome da guilda
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
                    // Campo descrição da guilda
                    TextField(
                      controller: _guildDescriptionController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: "Descrição (opcional)",
                        labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColorBlue.withOpacity(0.5))),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColorPurple)),
                      ),
                      maxLines: 3,
                      maxLength: 150,
                    ),
                    SizedBox(height: 20),
                    // Seleção de ícone
                    Text("Escolha um ícone:", style: TextStyle(color: accentColorBlue, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accentColorBlue.withOpacity(0.3)),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableGuildIcons.map((icon) {
                          bool isSelected = icon == _selectedGuildIcon;
                          return InkWell(
                            onTap: () {
                              setDialogState(() {
                                _selectedGuildIcon = icon;
                              });
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected ? accentColorPurple.withOpacity(0.3) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? accentColorPurple : accentColorBlue.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                icon,
                                color: isSelected ? accentColorPurple : accentColorBlue,
                                size: 24,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: _isProcessingGuildCreation ? null : () {
                    Navigator.of(dialogContext).pop();
                    _createGuild();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColorPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: _isProcessingGuildCreation 
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text("Criar Guilda"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text("Cancelar", style: TextStyle(color: textColor.withOpacity(0.7))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Função para criar a guilda
  Future<void> _createGuild() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        _showStyledDialog(
          titleText: "Erro",
          icon: Icons.error_outline,
          iconColor: Colors.red,
          contentWidgets: [
            Text("Você precisa estar logado para criar uma guilda.", style: TextStyle(color: textColor)),
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

    String guildName = _guildNameController.text.trim();
    if (guildName.isEmpty) {
      if (mounted) {
        _showStyledDialog(
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
      }
      return;
    }

    // Verificar se o usuário já está em uma guilda
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    if (userDoc.exists && (userDoc.data() as Map<String, dynamic>?)?['guildId'] != null) {
      if (mounted) {
        _showStyledDialog(
          titleText: "Já em uma Guilda",
          icon: Icons.info_outline,
          iconColor: Colors.orange,
          contentWidgets: [
            Text("Você já está em uma guilda. Saia da guilda atual antes de criar uma nova.", style: TextStyle(color: textColor)),
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

    if (mounted) {
      setState(() { _isProcessingGuildCreation = true; });
    }

    try {
      // Verificar se já existe uma guilda com o mesmo nome
      QuerySnapshot existingGuilds = await FirebaseFirestore.instance
          .collection('guilds')
          .where('name', isEqualTo: guildName)
          .get();

      if (existingGuilds.docs.isNotEmpty) {
        if (mounted) {
          _showStyledDialog(
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
          setState(() { _isProcessingGuildCreation = false; });
        }
        return;
      }

      // Calcular aura do usuário atual
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      int userAura = _calculateAura(userData);

      // Criar a guilda
      DocumentReference guildRef = await FirebaseFirestore.instance.collection('guilds').add({
        'name': guildName,
        'description': _guildDescriptionController.text.trim().isEmpty 
          ? 'Nenhuma descrição definida.' 
          : _guildDescriptionController.text.trim(),
        'ownerId': currentUser.uid,
        'ownerName': userData['playerName'] ?? currentUser.displayName ?? 'Jogador',
        'members': {currentUser.uid: 'Dono'},
        'memberCount': 1,
        'totalAura': userAura,
        'createdAt': FieldValue.serverTimestamp(),
        'iconData': _selectedGuildIcon.codePoint,
        'iconFontFamily': _selectedGuildIcon.fontFamily,
        'iconFontPackage': _selectedGuildIcon.fontPackage,
      });

      // Atualizar dados do usuário
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
        'guildId': guildRef.id,
        'guildName': guildName,
        'guildRole': 'Dono',
      });

      // Atualizar o estado local
      if (mounted) {
        setState(() {
          _userGuildId = guildRef.id;
        });

        _showStyledDialog(
          titleText: "Guilda Criada",
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
          contentWidgets: [
            Text("Guilda '$guildName' criada com sucesso!", style: TextStyle(color: textColor)),
          ],
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text("OK"),
            ),
          ],
        );

        // Navegar para a tela de gerenciamento da guilda
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GuildManagementScreen()),
        ).then((_) {
          // Atualizar status quando voltar
          _checkUserGuildStatus();
          _checkGuildRoleInvites();
        });
      }

    } catch (e) {
      _logger.e('Erro ao criar guilda', error: e);
      if (mounted) {
        _showStyledDialog(
          titleText: "Erro",
          icon: Icons.error_outline,
          iconColor: Colors.red,
          contentWidgets: [
            Text("Erro ao criar guilda. Tente novamente.", style: TextStyle(color: textColor)),
          ],
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK", style: TextStyle(color: accentColorBlue)),
            ),
          ],
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isProcessingGuildCreation = false; });
      }
    }
  }

  Widget _buildFriendRankingItem(Map<String, dynamic> friend, int index) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: primaryColor.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accentColorBlue.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: SizedBox(
          width: 80, // Aumentar largura para evitar overflow: 40 + 6 + 24 = 70px + margem
          height: 40,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Foto de perfil do amigo
              CircleAvatar(
                radius: 18, // Reduzir um pouco para economizar espaço
                backgroundColor: accentColorBlue.withOpacity(0.3),
                backgroundImage: friend['profileImageUrl'] != null && friend['profileImageUrl']!.isNotEmpty
                    ? NetworkImage(friend['profileImageUrl']!)
                    : null,
                child: friend['profileImageUrl'] == null || friend['profileImageUrl']!.isEmpty
                    ? Icon(Icons.person, color: textColor.withOpacity(0.7), size: 22)
                    : null,
              ),
              SizedBox(width: 6), // Reduzir espaçamento
              // Posição no ranking (estrela com número)
              SizedBox(
                width: 24, // Reduzir largura da estrela
                height: 24, // Reduzir altura da estrela
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.star_rounded, color: accentColorPurple, size: 20), // Reduzir tamanho da estrela
                    Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: textColor, // Número branco/textColor
                        fontWeight: FontWeight.bold,
                        fontSize: 10, // Reduzir tamanho da fonte
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        title: Text(
          friend['name'],
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nível ${friend['level']}',
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.whatshot_rounded, color: prColor, size: 14), // Ícone de chama para aura
                SizedBox(width: 4), // Espaço entre ícone e texto
                Text(
                  'Aura: ${friend['aura']}',
                  style: TextStyle(
                    color: prColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: accentColorBlue),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewOtherProfileScreen(
                userId: friend['id'],
                initialPlayerName: friend['name'],
              ),
            ),
          );
        },
      ),
    );
  }

  void _checkGuildInvites() {
    // Implemente a lógica para verificar convites de guilda
  }

  void _listenToFriendRequests() {
    final user = _auth.currentUser;
    if (user == null) return;

    _friendRequestSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('friendRequestsReceived')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          // _hasFriendRequest = snapshot.docs.isNotEmpty;
        });
      }
    }, onError: (error) {
      _logger.e('Erro no listener de pedidos de amizade', error: error);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Column(
        children: [
          // Botões fixos no topo
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildSocialButton(
                        context,
                        icon: Icons.group_add_rounded,
                        label: "Pedidos",
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendRequestsScreen()));
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildSocialButton(
                        context,
                        icon: Icons.people_alt_rounded,
                        label: "Amigos",
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MyFriendsScreen()));
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildSocialButton(
                        context,
                        icon: Icons.shield_rounded,
                        label: "Guilda",
                        onPressed: _handleGuildButtonPressed,
                        showBadge: _hasGuildRoleInvite,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildSocialButton(
                        context,
                        icon: Icons.mail_outline_rounded,
                        label: "Convites",
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const GuildInvitationsScreen()));
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Seção de busca
          _buildSearchSection(),

          // Título do Ranking
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              "Ranking de Aliados",
              style: TextStyle(
                color: accentColorBlue,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Lista de ranking de amigos
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: accentColorPurple))
                : _friendsList.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum amigo encontrado',
                          style: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        itemCount: _friendsList.length,
                        itemBuilder: (context, index) {
                          return _buildFriendRankingItem(_friendsList[index], index);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}