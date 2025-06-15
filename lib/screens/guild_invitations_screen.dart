// Em lib/screens/guild_invitations_screen.dart
// ignore_for_file: prefer_const_constructors, avoid_print, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'view_other_profile_screen.dart'; // REMOVIDO TEMPORARIAMENTE

// Cores (ajuste para suas constantes globais)
const Color primaryColor = Color(0xFF0A0E21);
const Color accentColorBlue = Color(0xFF40C4FF);
const Color accentColorPurple = Color(0xFF8A2BE2);
const Color textColor = Colors.white;
const Color panelBgColor = Color(0x991D1E33);
const Color greenStatColor = Colors.greenAccent;
const Color redAccentColor = Colors.redAccent;
const Color yellowWarningColor = Colors.yellowAccent;


// Modelo para informações do convite de guilda
class GuildInvitationInfo {
  final String guildId;
  final String guildName;
  final String inviterName;
  final String inviterId;
  final Timestamp timestamp;

  GuildInvitationInfo({
    required this.guildId,
    required this.guildName,
    required this.inviterName,
    required this.inviterId,
    required this.timestamp,
  });

  factory GuildInvitationInfo.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GuildInvitationInfo(
      guildId: doc.id, // O ID do documento é o guildId
      guildName: data['guildName'] ?? 'Guilda Desconhecida',
      inviterName: data['inviterName'] ?? 'Convidante Desconhecido',
      inviterId: data['inviterId'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}

class GuildInvitationsScreen extends StatefulWidget {
  const GuildInvitationsScreen({super.key});

  @override
  State<GuildInvitationsScreen> createState() => _GuildInvitationsScreenState();
}

class _GuildInvitationsScreenState extends State<GuildInvitationsScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  bool _isProcessingAccept = false;
  bool _isProcessingDecline = false;
  List<GuildInvitationInfo> _pendingInvitations = [];

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _fetchPendingInvitations();
    } else {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _fetchPendingInvitations() async {
    if (!mounted || _currentUser == null) return;
    setState(() { _isLoading = true; });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .collection('guildInvitations')
          .where('status', isEqualTo: 'pending')
          .orderBy('timestamp', descending: true)
          .get();

      List<GuildInvitationInfo> invitations = querySnapshot.docs
          .map((doc) => GuildInvitationInfo.fromFirestore(doc))
          .toList();

      if (mounted) {
        setState(() {
          _pendingInvitations = invitations;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erro ao buscar convites de guilda: $e");
      if (mounted) {
        setState(() { _isLoading = false; });
        _showStyledDialog(
          passedContext: context,
          titleText: "Erro",
          icon: Icons.error_outline,
          iconColor: Colors.red,
          contentWidgets: [
            Text("Erro ao carregar convites.", style: TextStyle(color: textColor)),
          ],
          actions: [
            _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true)
          ],
        );
      }
    }
  }

  Future<void> _acceptGuildInvitation(GuildInvitationInfo invitation) async {
    if (_currentUser == null || !mounted) return;

    DocumentSnapshot userDocCurrentForCheck = await FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).get();
    if ((userDocCurrentForCheck.data() as Map<String,dynamic>?)?['guildId'] != null) {
        if (mounted) {
            _showStyledDialog(
              passedContext: context,
              titleText: "Aviso",
              icon: Icons.warning,
              iconColor: yellowWarningColor,
              contentWidgets: [
                Text("Você já está em uma guilda. Saia da atual para aceitar um novo convite.", style: TextStyle(color: textColor))
              ],
              actions: [
                _buildDialogButton(context, "OK", () {
                  Navigator.of(context).pop();
                  _fetchPendingInvitations();
                }, true)
              ]
            );
        }
        return;
    }

    if (mounted) setState(() { _isProcessingAccept = true; });

    DocumentReference guildDocRef = FirebaseFirestore.instance.collection('guilds').doc(invitation.guildId);
    DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(_currentUser.uid);
    DocumentReference invitationDocRef = FirebaseFirestore.instance
        .collection('users').doc(_currentUser.uid)
        .collection('guildInvitations').doc(invitation.guildId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot userSnapshot = await transaction.get(userDocRef);
        DocumentSnapshot guildSnapshot = await transaction.get(guildDocRef);

        if (!userSnapshot.exists) throw Exception("Documento do usuário não existe.");
        if (!guildSnapshot.exists) {
          transaction.delete(invitationDocRef);
          throw Exception("Guilda não existe mais.");
        }

        Map<String, dynamic> guildData = guildSnapshot.data() as Map<String, dynamic>;

        int currentMemberCount = (guildData['memberCount'] ?? 0) as int;
        if (currentMemberCount >= 50) {
          transaction.update(invitationDocRef, {'status': 'error_guild_full'});
          throw Exception("A guilda '${invitation.guildName}' está cheia.");
        }

        // Não precisamos mais dos dados do usuário já que não atualizamos totalAura
        
        Map<String, dynamic> updatedMembers = Map<String, dynamic>.from(guildData['members'] ?? {});
        if (updatedMembers.containsKey(_currentUser.uid)) {
          print("Usuário já é membro. Apenas processando convite.");
          transaction.delete(invitationDocRef);
          return; 
        }

        updatedMembers[_currentUser.uid] = 'Membro';
        int updatedMemberCount = ((guildData['memberCount'] ?? 0) as int) + 1;
        // Removendo atualização da aura total - será calculada dinamicamente

        transaction.update(guildDocRef, {
          'members': updatedMembers,
          'memberCount': updatedMemberCount,
          // 'totalAura': updatedTotalAura, // Removido para evitar problemas de permissão
        });

        transaction.update(userDocRef, {
          'guildId': invitation.guildId,
          'guildName': invitation.guildName,
          'guildRole': 'Membro',
        });

        transaction.delete(invitationDocRef);
      });

      if (mounted) {
        _showStyledDialog(
          passedContext: context,
          titleText: "Sucesso",
          icon: Icons.check_circle_outline,
          iconColor: Colors.greenAccent,
          contentWidgets: [
            Text("Você entrou na guilda ${invitation.guildName}!", style: TextStyle(color: textColor))
          ],
          actions: [
            _buildDialogButton(context, "OK", () {
              Navigator.of(context).pop();
              _fetchPendingInvitations();
            }, true)
          ]
        );
      }
    } catch (e) {
      print("Erro ao aceitar convite de guilda: $e");
      if (mounted) {
        _showStyledDialog(
          passedContext: context,
          titleText: "Erro",
          icon: Icons.error_outline,
          iconColor: Colors.red,
          contentWidgets: [
            Text("Erro ao entrar na guilda. Tente novamente.", style: TextStyle(color: textColor)),
          ],
          actions: [
            _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true)
          ],
        );
      }
    } finally {
      if (mounted) setState(() { _isProcessingAccept = false; });
    }
  }

  Future<void> _declineGuildInvitation(String guildId) async {
    if (_currentUser == null || !mounted || _isProcessingDecline) return;
    setState(() { _isProcessingDecline = true; });

    try {
      await FirebaseFirestore.instance
          .collection('users').doc(_currentUser.uid)
          .collection('guildInvitations').doc(guildId)
          .delete(); // Ou update({'status': 'declined_by_user'});

      if (mounted) {
        _showStyledDialog(
          passedContext: context,
          titleText: "Convite Recusado",
          icon: Icons.info_outline,
          iconColor: Colors.orange,
          contentWidgets: [
            Text("Convite de guilda recusado.", style: TextStyle(color: textColor)),
          ],
          actions: [
            _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true)
          ],
        );
        // Remove da lista local
        setState(() {
          _pendingInvitations.removeWhere((inv) => inv.guildId == guildId);
        });
      }
    } catch (e) {
      print("Erro ao recusar convite de guilda: $e");
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
      if (mounted) setState(() { _isProcessingDecline = false; });
    }
  }

  Widget _buildDialogButton(BuildContext context, String text, VoidCallback onPressed, bool isPrimary) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: Text("Convites de Guilda", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: accentColorBlue),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColorPurple))
          : _pendingInvitations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mail_lock_outlined, size: 80, color: textColor.withOpacity(0.5)),
                      SizedBox(height: 16),
                      Text(
                        "Nenhum convite pendente",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Você não tem convites de guilda no momento",
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchPendingInvitations,
                  color: accentColorPurple,
                  backgroundColor: primaryColor,
                  child: ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemCount: _pendingInvitations.length,
                    itemBuilder: (context, index) {
                      final invitation = _pendingInvitations[index];
                      return Card(
                        color: panelBgColor,
                        margin: EdgeInsets.symmetric(vertical: 6.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: Icon(Icons.shield_moon_outlined, color: accentColorBlue, size: 30),
                          title: Text(invitation.guildName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                          subtitle: Text("Convidado por: ${invitation.inviterName}", style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12)),
                          trailing: (_isProcessingAccept || _isProcessingDecline)
                            ? SizedBox(height:24, width:24, child:CircularProgressIndicator(strokeWidth:2, color:accentColorPurple))
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.check_circle_rounded, color: greenStatColor),
                                    tooltip: "Aceitar",
                                    onPressed: () => _acceptGuildInvitation(invitation),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.cancel_rounded, color: redAccentColor),
                                    tooltip: "Recusar",
                                    onPressed: () => _declineGuildInvitation(invitation.guildId),
                                  ),
                                ],
                              ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}