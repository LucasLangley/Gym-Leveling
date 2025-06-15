// Em lib/screens/guild_profile_screen.dart
// ignore_for_file: prefer_const_constructors, avoid_print, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/aura_calculator.dart' as aura_utils;
// Para pow()

// Importações de outras telas
import 'guild_management_screen.dart'; // Para navegação
import 'view_other_profile_screen.dart'; // Adicionar no topo do arquivo com os outros imports

// Cores
const Color primaryColor = Color(0xFF0A0E21);
const Color accentColorBlue = Color(0xFF40C4FF);
const Color accentColorPurple = Color(0xFF8A2BE2);
const Color textColor = Colors.white;
const Color panelBgColor = Color(0x991D1E33);
const Color greenStatColor = Colors.greenAccent;
const Color yellowWarningColor = Colors.yellowAccent; // Adicionado
const Color prColor = Colors.amberAccent;

const Map<String, Color> itemRankColors = {
  'E': Colors.grey, 'D': Colors.green, 'C': Colors.yellowAccent,
  'B': Color(0xFFADADAD), 'A': Colors.orange, 'S': Colors.redAccent,
  'SS': Colors.pinkAccent, 'SSS': Color(0xFF6F7FFF), 'Global': accentColorPurple,
};

class Item {
  final String id; final String name; final String slotType; final String rank;
  final DateTime dateAcquired; final IconData icon; bool isNew;
  final Map<String, int> statBonuses;
  Item({ required this.id, required this.name, required this.slotType, required this.rank,
    required this.dateAcquired, required this.icon, this.isNew = false, this.statBonuses = const {},});
}

final List<Item> allGameItemsMock = [ // Mantenha sua lista mestre de itens
  Item(id: 'capacete_e', name: 'itemElmoFerro', slotType: 'head', rank: 'E', dateAcquired: DateTime.now(), icon: Icons.account_circle_outlined, statBonuses: {'VIT': 2}),
  Item(id: 'peitoral_d', name: 'itemCotaMalha', slotType: 'chest', rank: 'D', dateAcquired: DateTime.now(), icon: Icons.shield_outlined, statBonuses: {'VIT': 5, 'FOR': 1}),
  Item(id: 'espada_a', name: 'itemLaminaAgil', slotType: 'rightHand', rank: 'A', dateAcquired: DateTime.now().subtract(const Duration(days: 1)), icon: Icons.pan_tool_alt_outlined, statBonuses: {'FOR': 8, 'AGI': 3}),
  Item(id: 'botas_s', name: 'itemBotasSombrias', slotType: 'feet', rank: 'S', dateAcquired: DateTime.now().subtract(const Duration(days: 2)), icon: Icons.do_not_step, statBonuses: {'AGI': 7, 'PER': 2}),
  Item(id: 'colar_sss', name: 'itemColarMonarca', slotType: 'necklace', rank: 'SSS', dateAcquired: DateTime.now().subtract(const Duration(days: 10)), icon: Icons.circle_outlined, statBonuses: {'INT': 10, 'MP_MAX_BONUS': 50}),
  Item(id: 'anel_poder', name: 'itemAnelPoder', slotType: 'accessoryL', rank: 'Global', dateAcquired: DateTime.now(), icon: Icons.star_border_outlined, statBonuses: {'FOR': 2, 'AGI': 2, 'VIT': 2, 'INT': 2, 'PER': 2}),
];

class EquipmentSlotWidget extends StatelessWidget {
  final String slotName; final IconData placeholderIcon; final bool isEquipped;
  final String? itemName; final Color? itemRankColor;
  const EquipmentSlotWidget({
    required this.slotName, required this.placeholderIcon, this.isEquipped = false,
    this.itemName, this.itemRankColor, super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: panelBgColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEquipped ? (itemRankColor ?? accentColorBlue) : Colors.grey.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isEquipped ? Icons.check_circle : placeholderIcon,
            color: isEquipped ? (itemRankColor ?? accentColorBlue) : Colors.grey.withOpacity(0.5),
            size: 24,
          ),
          if (isEquipped && itemName != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                itemName!,
                style: TextStyle(
                  color: itemRankColor ?? accentColorBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class BodyViewerPlaceholder extends StatelessWidget {
  const BodyViewerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 300,
      decoration: BoxDecoration(
        color: panelBgColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColorBlue.withOpacity(0.3)),
      ),
      child: Center(
        child: Icon(
          Icons.person_outline,
          size: 100,
          color: accentColorBlue.withOpacity(0.5),
        ),
      ),
    );
  }
}

class Guild {
  final String id;
  final String name;
  final String ownerId;
  final String ownerName;
  final String description;
  final String? iconUrl;
  final Timestamp createdAt;
  final int memberCount;
  final int totalAura;
  final Map<String, String> members; // UID -> Cargo (String)

  Guild({
    required this.id, required this.name, required this.ownerId, required this.ownerName,
    this.description = "Nenhuma descrição definida.", this.iconUrl,
    required this.createdAt, required this.memberCount, required this.totalAura, required this.members,
  });

  factory Guild.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Calcula a aura total somando base + bônus de todos os membros
    int totalAura = 0;
    Map<String, String> members = Map<String, String>.from(data['members'] ?? {});

    return Guild(
      id: doc.id,
      name: data['name'] ?? 'Guilda Desconhecida',
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? 'Dono Desconhecido',
      description: data['description'] ?? 'Nenhuma descrição.',
      iconUrl: data['iconUrl'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      memberCount: data['memberCount'] ?? 0,
      totalAura: totalAura, // Será calculado depois
      members: members,
    );
  }
}

class GuildMemberInfo {
  final String uid;
  final String name;
  final String role;
  final int aura;
  final int level;
  final String? profileImageUrl;

  GuildMemberInfo({required this.uid, required this.name, required this.role, required this.aura, required this.level, this.profileImageUrl});
}

class GuildProfileScreen extends StatefulWidget {
  final String guildId;

  const GuildProfileScreen({
    required this.guildId,
    super.key,
  });

  @override
  State<GuildProfileScreen> createState() => _GuildProfileScreenState();
}

class _GuildProfileScreenState extends State<GuildProfileScreen> {
  bool _isLoadingData = true;
  Guild? _guild;
  List<GuildMemberInfo> _members = [];
  bool _isGuildMember = false;
  bool _hasPendingRequest = false;
  bool _isProcessingRequest = false;
  Map<String, dynamic>? _pendingRoleInvite;

  // Variáveis para ordenação
  String _currentSort = 'cargo'; // 'cargo' ou 'aura'
  bool _isAscending = true;

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

  @override
  void initState() {
    super.initState();
    _loadGuildData();
  }

  Future<void> _checkMembershipStatusOnly() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() { _isProcessingRequest = true; });

    try {
      // Verifica se é membro da guilda
      _isGuildMember = _guild?.members.containsKey(currentUser.uid) ?? false;

      // Verifica se já tem uma solicitação pendente
      DocumentSnapshot requestDoc = await FirebaseFirestore.instance
          .collection('guilds')
          .doc(widget.guildId)
          .collection('joinRequests')
          .doc(currentUser.uid)
          .get();

      // Verifica se tem convite para cargo (sem mostrar diálogo automaticamente)
      DocumentSnapshot roleInviteDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('guildRoleInvites')
          .doc(widget.guildId)
          .get();

      if (mounted) {
        setState(() {
          _hasPendingRequest = requestDoc.exists;
          _pendingRoleInvite = roleInviteDoc.exists ? roleInviteDoc.data() as Map<String, dynamic> : null;
          _isProcessingRequest = false;
        });
      }
    } catch (e) {
      print("Erro ao verificar status de membro da guilda: $e");
      if (mounted) {
        setState(() { _isProcessingRequest = false; });
      }
    }
  }

  // Função para verificar e mostrar convite de cargo quando solicitado pelo usuário
  void _checkAndShowRoleInvite() {
    if (_pendingRoleInvite != null) {
      _showRoleInviteDialog();
    }
  }



  void _showRoleInviteDialog() {
    if (_pendingRoleInvite == null) return;

    String inviterName = _pendingRoleInvite!['inviterName'] ?? 'Alguém';
    String role = _pendingRoleInvite!['role'] ?? 'Membro';

    _showStyledDialog<void>(
      passedContext: context,
      titleText: "Convite para Cargo",
      icon: Icons.workspace_premium_rounded,
      iconColor: accentColorPurple,
      contentWidgets: [
        Text(
          "$inviterName te convidou para se tornar $role na Guilda ${_guild?.name}!",
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor, fontSize: 16),
        ),
      ],
      actions: [
        _buildDialogButton(
          context,
          "Recusar",
          () {
            Navigator.of(context).pop();
            _declineRoleInvite();
          },
          false,
        ),
        _buildDialogButton(
          context,
          "Aceitar",
          () {
            Navigator.of(context).pop();
            _acceptRoleInvite();
          },
          true,
        ),
      ],
    );
  }

  Future<void> _acceptRoleInvite() async {
    if (_pendingRoleInvite == null || _guild == null) return;

    setState(() { _isProcessingRequest = true; });

    try {
      final batch = FirebaseFirestore.instance.batch();
      String role = _pendingRoleInvite!['role'] as String? ?? 'Membro';

      // Atualiza o cargo do usuário na guilda
      Map<String, String> updatedMembers = Map<String, String>.from(_guild!.members);
      updatedMembers[FirebaseAuth.instance.currentUser!.uid] = role;

      // Atualiza a guilda
      batch.update(
        FirebaseFirestore.instance.collection('guilds').doc(widget.guildId),
        {'members': updatedMembers},
      );

      // Atualiza os dados do usuário
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid),
        {
          'guildId': widget.guildId,
          'guildName': _guild!.name,
          'guildRole': role,
        },
      );

      // Remove o convite
      batch.delete(
        FirebaseFirestore.instance.collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('guildRoleInvites')
            .doc(widget.guildId),
      );

      await batch.commit();

      if (mounted) {
        _showStyledDialog(
          passedContext: context,
          titleText: "Sucesso",
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
          contentWidgets: [
            Text("Você aceitou o cargo de $role!", style: TextStyle(color: textColor)),
          ],
          actions: [
            _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true)
          ],
        );
        _loadGuildData(); // Recarrega os dados da guilda
      }
    } catch (e) {
      print("Erro ao aceitar convite para cargo: $e");
      if (mounted) {
        _showStyledDialog(
          passedContext: context,
          titleText: "Erro",
          icon: Icons.error_outline,
          iconColor: Colors.red,
          contentWidgets: [
            Text("Erro ao aceitar convite. Tente novamente.", style: TextStyle(color: textColor)),
          ],
          actions: [
            _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true)
          ],
        );
      }
    } finally {
      if (mounted) {
        setState(() { 
          _isProcessingRequest = false;
          _pendingRoleInvite = null;
        });
      }
    }
  }

  Future<void> _declineRoleInvite() async {
    if (_pendingRoleInvite == null) return;

    setState(() { _isProcessingRequest = true; });

    try {
      // Remove o convite
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('guildRoleInvites')
          .doc(widget.guildId)
          .delete();

      if (mounted) {
        _showStyledDialog(
          passedContext: context,
          titleText: "Convite Recusado",
          icon: Icons.info_outline,
          iconColor: Colors.orange,
          contentWidgets: [
            Text("Convite recusado.", style: TextStyle(color: textColor)),
          ],
          actions: [
            _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true)
          ],
        );
      }
    } catch (e) {
      print("Erro ao recusar convite para cargo: $e");
      if (mounted) {
        _showStyledDialog(
          passedContext: context,
          titleText: "Erro",
          icon: Icons.error_outline,
          iconColor: Colors.red,
          contentWidgets: [
            Text("Erro ao recusar convite. Tente novamente.", style: TextStyle(color: textColor)),
          ],
          actions: [
            _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true)
          ],
        );
      }
    } finally {
      if (mounted) {
        setState(() { 
          _isProcessingRequest = false;
          _pendingRoleInvite = null;
        });
      }
    }
  }

  Future<void> _sendJoinRequest() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showStyledDialog(
        passedContext: context,
        titleText: "Erro",
        icon: Icons.error_outline,
        iconColor: Colors.redAccent,
        contentWidgets: [
          Text(
            "Você precisa estar logado para solicitar entrada na guilda.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: textColor, fontSize: 16)
          )
        ],
        actions: [
          _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true)
        ],
      );
      return;
    }

    // Verifica se o usuário já é membro de uma guilda
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (userDoc.exists && (userDoc.data() as Map<String, dynamic>?)?['guildId'] != null) {
      _showStyledDialog(
        passedContext: context,
        titleText: "Erro",
        icon: Icons.error_outline,
        iconColor: Colors.redAccent,
        contentWidgets: [
          Text(
            "Você já é membro de uma guilda. Saia da guilda atual antes de solicitar entrada em outra.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: textColor, fontSize: 16)
          )
        ],
        actions: [
          _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true)
        ],
      );
      return;
    }

    setState(() { _isProcessingRequest = true; });

    try {
      // Adiciona a solicitação na subcoleção 'joinRequests' da guilda
      await FirebaseFirestore.instance
          .collection('guilds')
          .doc(widget.guildId)
          .collection('joinRequests')
          .doc(currentUser.uid)
          .set({
            'userId': currentUser.uid,
            'userName': currentUser.displayName ?? "Jogador",
            'timestamp': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        setState(() { 
          _hasPendingRequest = true;
          _isProcessingRequest = false;
        });
        
        _showStyledDialog(
          passedContext: context,
          titleText: "Sucesso",
          icon: Icons.check_circle_rounded,
          iconColor: Colors.green,
          contentWidgets: [
            Text(
              "Solicitação enviada para ${_guild?.name}!",
              textAlign: TextAlign.center,
              style: const TextStyle(color: textColor, fontSize: 16)
            )
          ],
          actions: [
            _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true)
          ],
        );
      }
    } catch (e) {
      print("Erro ao enviar solicitação para a guilda: $e");
      if (mounted) {
        setState(() { _isProcessingRequest = false; });
        _showStyledDialog(
          passedContext: context,
          titleText: "Erro",
          icon: Icons.error_outline,
          iconColor: Colors.redAccent,
          contentWidgets: [
            Text(
              "Erro ao enviar solicitação. Tente novamente.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: textColor, fontSize: 16)
            )
          ],
          actions: [
            _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true)
          ],
        );
      }
    }
  }

  Future<void> _loadGuildData() async {
    setState(() { _isLoadingData = true; });
    try {
      DocumentSnapshot guildDoc = await FirebaseFirestore.instance.collection('guilds').doc(widget.guildId).get();
      if (guildDoc.exists) {
        Guild currentGuild = Guild.fromFirestore(guildDoc);

        // Busca os membros da guilda com suas auras, níveis e URLs de imagem
        List<GuildMemberInfo> loadedMembers = [];
        for (var memberIdEntry in currentGuild.members.entries) {
          String memberId = memberIdEntry.key;
          String memberRole = memberIdEntry.value;
          DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(memberId).get();
          if (userDoc.exists) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            loadedMembers.add(GuildMemberInfo(
              uid: memberId,
              name: userData['playerName'] ?? 'Desconhecido',
              role: memberRole,
              aura: _calculateAura(userData),
              level: userData['level'] ?? 1,
              profileImageUrl: userData['profileImageUrl'] as String?,
            ));
          }
        }

        // Calcula a aura total somando todas as auras dos membros
        int totalCalculatedAura = loadedMembers.fold(0, (total, member) => total + member.aura);
        
        // Atualiza o objeto da guilda com a aura total calculada
        currentGuild = Guild(
          id: currentGuild.id,
          name: currentGuild.name,
          ownerId: currentGuild.ownerId,
          ownerName: currentGuild.ownerName,
          description: currentGuild.description,
          iconUrl: currentGuild.iconUrl,
          createdAt: currentGuild.createdAt,
          memberCount: currentGuild.memberCount,
          totalAura: totalCalculatedAura, // Aura total calculada
          members: currentGuild.members,
        );

        // A aura total é calculada dinamicamente, não precisamos atualizá-la no banco
        // Isso evita problemas de permissão já que apenas o dono pode atualizar a guilda

        // Ordena os membros inicialmente por cargo (se houver líder/oficial)
        loadedMembers.sort((a, b) {
          // Prioriza o líder e oficiais no topo
          if (a.role == 'Líder' && b.role != 'Líder') return -1;
          if (a.role != 'Líder' && b.role == 'Líder') return 1;
          if (a.role == 'Oficial' && b.role != 'Oficial') return -1;
          if (a.role != 'Oficial' && b.role == 'Oficial') return 1;
          return b.aura.compareTo(a.aura); // Depois, por aura
        });

        if (mounted) {
          setState(() {
            _guild = currentGuild;
            _members = loadedMembers;
          });
        }
      } else {
        if (mounted) {
          _showStyledDialog(
            passedContext: context,
            titleText: "Erro",
            icon: Icons.error_outline,
            iconColor: Colors.red,
            contentWidgets: [
              Text("Guilda não encontrada.", style: TextStyle(color: textColor)),
            ],
            actions: [
              _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true)
            ],
          );
        }
      }
    } catch (e) {
      print("Erro ao carregar dados da guilda: $e");
      if (mounted) {
        _showStyledDialog(
          passedContext: context,
          titleText: "Erro",
          icon: Icons.error_outline,
          iconColor: Colors.red,
          contentWidgets: [
            Text("Erro ao carregar guilda. Tente novamente.", style: TextStyle(color: textColor)),
          ],
          actions: [
            _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true)
          ],
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoadingData = false; });
      }
    }
    // Só verifica membership status, sem mostrar diálogos automaticamente
    _checkMembershipStatusOnly();
  }

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
    List<GuildMemberInfo> filteredMembers = List.from(_members);

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

  Widget _buildJoinButton() {
    return ElevatedButton.icon(
      icon: Icon(
        _hasPendingRequest ? Icons.hourglass_top_rounded : Icons.group_add_rounded,
        size: 18,
      ),
      label: Text(_hasPendingRequest ? "Solicitação Enviada" : "Solicitar Entrada"),
      onPressed: _isProcessingRequest || _hasPendingRequest ? null : _sendJoinRequest,
      style: ElevatedButton.styleFrom(
        backgroundColor: _hasPendingRequest ? Colors.grey.shade700 : accentColorBlue.withOpacity(0.8),
        foregroundColor: textColor,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        minimumSize: Size(double.infinity, 45),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: primaryColor,
        appBar: AppBar(
          title: Text("Carregando Guilda...", style: TextStyle(color: textColor)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: accentColorBlue),
          leading: IconButton(icon: Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()),
        ),
        body: Center(child: CircularProgressIndicator(color: accentColorPurple)),
      );
    }

    if (_guild == null) {
      return Scaffold(
        backgroundColor: primaryColor,
        appBar: AppBar(
          title: Text("Guilda Não Encontrada", style: TextStyle(color: Colors.redAccent)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: accentColorBlue),
          leading: IconButton(icon: Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.of(context).pop()),
        ),
        body: Center(child: Text("Guilda não encontrada", style: TextStyle(color: Colors.redAccent, fontSize: 18))),
      );
    }

    User? currentUser = FirebaseAuth.instance.currentUser;
    bool isOwner = currentUser?.uid == _guild!.ownerId;

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_guild!.name, style: TextStyle(color: accentColorBlue, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.0)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: accentColorBlue), onPressed: () => Navigator.of(context).pop()),
        actions: [
          if (isOwner)
            IconButton(
              icon: Icon(Icons.settings, color: accentColorBlue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GuildManagementScreen()),
                ).then((_) => _loadGuildData());
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: panelBgColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColorBlue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Descrição:", style: TextStyle(color: accentColorBlue, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_guild!.description, style: TextStyle(color: textColor)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Líder:", style: TextStyle(color: accentColorBlue, fontSize: 14)),
                            Text(_guild!.ownerName, style: TextStyle(color: textColor)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("Membros:", style: TextStyle(color: accentColorBlue, fontSize: 14)),
                            Text("${_guild!.memberCount}", style: TextStyle(color: textColor)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.whatshot_rounded, color: prColor, size: 22),
                        const SizedBox(width: 8),
                        Text("AURA TOTAL: ", style: TextStyle(color: accentColorBlue, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text("${_guild!.totalAura}", style: TextStyle(color: prColor, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16), // Espaço abaixo das informações da guilda
              
              // Botão de convite para cargo pendente (se houver)
              if (_pendingRoleInvite != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.workspace_premium_rounded, size: 18),
                    label: Text("Ver Convite de Cargo Pendente"),
                    onPressed: _checkAndShowRoleInvite,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColorPurple.withOpacity(0.8),
                      foregroundColor: textColor,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      minimumSize: Size(double.infinity, 45),
                    ),
                  ),
                ),
              
              // Botão de solicitar entrada (se não for membro)
              if (!_isGuildMember && !_hasPendingRequest && !_isProcessingRequest && _pendingRoleInvite == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0), // Padding para o botão
                  child: _buildJoinButton(),
                ),
              SizedBox(height: 16), // Espaço entre o botão e o título Membros da Guilda
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), // Removido top padding extra
                child: Text(
                  "Membros da Guilda:",
                  style: TextStyle(color: accentColorBlue, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              
              // Botões de ordenação
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                  SizedBox(width: 16),
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
              
              _isLoadingData
                ? Center(child: CircularProgressIndicator(color: accentColorPurple))
                : _members.isEmpty
                    ? Text("Nenhum membro encontrado.", style: TextStyle(color: textColor.withOpacity(0.7)))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _getFilteredMembers().length,
                        itemBuilder: (context, index) {
                          final member = _getFilteredMembers()[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0.0),
                            color: panelBgColor.withOpacity(0.6),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViewOtherProfileScreen(
                                      userId: member.uid,
                                      initialPlayerName: member.name,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12.0),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    // Foto de perfil do membro
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: accentColorBlue.withOpacity(0.3),
                                      backgroundImage: member.profileImageUrl != null && member.profileImageUrl!.isNotEmpty
                                          ? NetworkImage(member.profileImageUrl!)
                                          : null,
                                      child: member.profileImageUrl == null || member.profileImageUrl!.isEmpty
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
                                              Expanded(
                                                child: Row(
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
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, color: textColor.withOpacity(0.5), size: 18),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}