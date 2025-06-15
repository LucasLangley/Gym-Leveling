// Em lib/screens/friend_requests_screen.dart
// ignore_for_file: prefer_const_constructors, avoid_print, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_other_profile_screen.dart';

// Cores
const Color primaryColor = Color(0xFF0A0E21);
const Color accentColorBlue = Color(0xFF40C4FF);
const Color accentColorPurple = Color(0xFF8A2BE2);
const Color textColor = Colors.white;
const Color panelBgColor = Color(0x991D1E33);
const Color greenStatColor = Colors.greenAccent;
const Color redAccentColor = Colors.redAccent;

class FriendRequestInfo {
  final String senderId;
  final String senderName;
  final Timestamp timestamp;
  final String? profileImageUrl;

  FriendRequestInfo({
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    this.profileImageUrl,
  });

  factory FriendRequestInfo.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FriendRequestInfo(
      senderId: doc.id,
      senderName: data['senderName'] ?? 'Nome Desconhecido',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      profileImageUrl: data['profileImageUrl'], // Pode ser null
    );
  }
}

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  bool _isLoading = true;
  List<FriendRequestInfo> _pendingRequests = [];
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _fetchPendingRequests();
    } else {
      if (mounted) { // Garante que o widget está montado antes de chamar setState
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _fetchPendingRequests() async {
    if (!mounted || _currentUser == null) return;
    setState(() { _isLoading = true; });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .collection('friendRequestsReceived')
          .where('status', isEqualTo: 'pending')
          .orderBy('timestamp', descending: true)
          .get();

      List<FriendRequestInfo> requests = [];
      
      // Para cada pedido, buscar informações completas do usuário
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        Map<String, dynamic> requestData = doc.data() as Map<String, dynamic>;
        String senderId = doc.id;
        
        // Buscar dados completos do usuário que enviou o pedido
        DocumentSnapshot senderDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(senderId)
            .get();
        
        String senderName = requestData['senderName'] ?? 'Nome Desconhecido';
        String? profileImageUrl;
        
        if (senderDoc.exists) {
          Map<String, dynamic>? senderData = senderDoc.data() as Map<String, dynamic>?;
          if (senderData != null) {
            // Atualizar nome se mudou no perfil do usuário
            senderName = senderData['playerName'] ?? senderName;
            profileImageUrl = senderData['profileImageUrl'];
          }
        }
        
        requests.add(FriendRequestInfo(
          senderId: senderId,
          senderName: senderName,
          timestamp: requestData['timestamp'] ?? Timestamp.now(),
          profileImageUrl: profileImageUrl,
        ));
      }

      if (mounted) {
        setState(() {
          _pendingRequests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erro ao buscar pedidos de amizade: $e");
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao carregar pedidos de amizade."), backgroundColor: Colors.redAccent)
        );
      }
    }
  }

  Future<void> _acceptFriendRequest(String senderId, String senderName) async {
    if (_currentUser == null || !mounted) return;
    
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Obter nome do usuário atual para adicionar ao amigo
    DocumentSnapshot currentUserProfile = await FirebaseFirestore.instance
        .collection('users').doc(_currentUser.uid).get();
    String currentUserNameForFriend = (currentUserProfile.data() as Map<String,dynamic>?)?['playerName'] 
        ?? _currentUser.displayName ?? "Novo Amigo";

    // Adicionar amigo à lista do usuário atual
    DocumentReference currentUserFriendRef = FirebaseFirestore.instance
        .collection('users').doc(_currentUser.uid)
        .collection('friends').doc(senderId);
    batch.set(currentUserFriendRef, {
      'friendName': senderName,
      'friendshipDate': FieldValue.serverTimestamp(),
    });

    // Adicionar usuário atual à lista de amigos do remetente
    DocumentReference senderFriendRef = FirebaseFirestore.instance
        .collection('users').doc(senderId)
        .collection('friends').doc(_currentUser.uid);
    batch.set(senderFriendRef, {
      'friendName': currentUserNameForFriend,
      'friendshipDate': FieldValue.serverTimestamp(),
    });

    // Remover pedido de amizade
    DocumentReference requestDocRef = FirebaseFirestore.instance
        .collection('users').doc(_currentUser.uid)
        .collection('friendRequestsReceived').doc(senderId);
    batch.delete(requestDocRef);

    // Incrementar friendCount apenas do usuário atual (o que aceita o pedido)
    // O friendCount do remetente será atualizado via Cloud Function ou manualmente
    DocumentReference currentUserRef = FirebaseFirestore.instance
        .collection('users').doc(_currentUser.uid);
    
    batch.update(currentUserRef, {'friendCount': FieldValue.increment(1)});

    try {
      await batch.commit();
      
      // Tentar atualizar friendCount do remetente - se falhar, não é crítico
      FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .update({'friendCount': FieldValue.increment(1)})
          .catchError((e) {
        print("Aviso: Não foi possível atualizar friendCount do amigo: $e");
        // Ignorar erro - não é crítico para a funcionalidade
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Você e $senderName agora são amigos!"), backgroundColor: Colors.green)
        );
        _fetchPendingRequests();
      }
    } catch (e) {
      print("Erro ao aceitar pedido de amizade: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao aceitar pedido. Tente novamente."), backgroundColor: Colors.redAccent)
        );
      }
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

  Future<void> _declineFriendRequest(String senderId) async {
    if (_currentUser == null || !mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('users').doc(_currentUser.uid)
          .collection('friendRequestsReceived').doc(senderId)
          .delete();

      if (mounted) {
        _showStyledDialog(
          passedContext: context,
          titleText: "Sucesso",
          icon: Icons.check_circle_outline,
          iconColor: Colors.greenAccent,
          contentWidgets: [
            Text("Pedido de amizade recusado.", style: TextStyle(color: textColor))
          ],
          actions: [
            _buildDialogButton(context, "OK", () {
              Navigator.of(context).pop();
              _fetchPendingRequests();
            }, true)
          ]
        );
      }
    } catch (e) {
      print("Erro ao recusar pedido de amizade: $e");
      if (mounted) {
        _showStyledDialog(
          passedContext: context,
          titleText: "Erro",
          icon: Icons.error_outline,
          iconColor: Colors.redAccent,
          contentWidgets: [
            Text("Erro ao recusar pedido. Tente novamente.", style: TextStyle(color: textColor))
          ],
          actions: [
            _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true)
          ]
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: Text("Pedidos de Amizade", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: accentColorBlue),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColorPurple))
          : _pendingRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_add_outlined, size: 80, color: textColor.withOpacity(0.5)),
                      SizedBox(height: 20),
                      Text(
                        "Nenhum pedido de amizade pendente.",
                        style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 16),
                      ),
                    ],
                  )
                )
              : RefreshIndicator(
                  onRefresh: _fetchPendingRequests,
                  color: accentColorPurple,
                  backgroundColor: primaryColor,
                  child: ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemCount: _pendingRequests.length,
                    itemBuilder: (context, index) {
                      final request = _pendingRequests[index];
                      return Card(
                        color: panelBgColor,
                        margin: EdgeInsets.symmetric(vertical: 6.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: accentColorBlue.withOpacity(0.3),
                            backgroundImage: request.profileImageUrl != null && request.profileImageUrl!.isNotEmpty
                                ? NetworkImage(request.profileImageUrl!)
                                : null,
                            child: request.profileImageUrl == null || request.profileImageUrl!.isEmpty
                                ? Icon(Icons.person, color: textColor.withOpacity(0.7), size: 30)
                                : null,
                          ),
                          title: Text(request.senderName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                          subtitle: Text("Enviou um pedido de amizade", style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewOtherProfileScreen(
                                  userId: request.senderId,
                                  initialPlayerName: request.senderName,
                                ),
                              ),
                            );
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.check_circle_outline_rounded, color: greenStatColor),
                                tooltip: "Aceitar",
                                onPressed: () => _acceptFriendRequest(request.senderId, request.senderName),
                              ),
                              IconButton(
                                icon: Icon(Icons.cancel_outlined, color: redAccentColor),
                                tooltip: "Recusar",
                                onPressed: () => _declineFriendRequest(request.senderId),
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