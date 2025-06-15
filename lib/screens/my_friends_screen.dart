// Em lib/screens/my_friends_screen.dart
// ignore_for_file: prefer_const_constructors, avoid_print, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_other_profile_screen.dart'; // Para navegar para o perfil do amigo

// Cores (ajuste para suas constantes globais)
const Color primaryColor = Color(0xFF0A0E21);
const Color accentColorBlue = Color(0xFF40C4FF);
const Color accentColorPurple = Color(0xFF8A2BE2);
const Color textColor = Colors.white;
const Color panelBgColor = Color(0x991D1E33);
const Color redAccentColor = Colors.redAccent;

// Modelo para informações do amigo
class FriendInfo {
  final String friendId;
  final String friendName;
  final Timestamp friendshipDate;

  FriendInfo({
    required this.friendId,
    required this.friendName,
    required this.friendshipDate,
  });

  factory FriendInfo.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FriendInfo(
      friendId: doc.id,
      friendName: data['friendName'] ?? 'Nome Desconhecido',
      friendshipDate: data['friendshipDate'] ?? Timestamp.now(),
    );
  }
}

class MyFriendsScreen extends StatefulWidget {
  const MyFriendsScreen({super.key});

  @override
  State<MyFriendsScreen> createState() => _MyFriendsScreenState();
}

class _MyFriendsScreenState extends State<MyFriendsScreen> {
  bool _isLoading = true;
  List<FriendInfo> _friendsList = [];
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _fetchFriends();
    } else {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _fetchFriends() async {
    if (!mounted || _currentUser == null) return;
    setState(() { _isLoading = true; });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid) // Removido '!' desnecessário se já verificado
          .collection('friends')
          .orderBy('friendName', descending: false) // Ordena por nome
          .get();

      List<FriendInfo> friends = querySnapshot.docs
          .map((doc) => FriendInfo.fromFirestore(doc))
          .toList();

      if (mounted) {
        setState(() {
          _friendsList = friends;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erro ao buscar lista de amigos: $e");
      if (mounted) {
        setState(() { _isLoading = false; });
        _showStyledDialog(
          context: context,
          titleText: "Erro",
          icon: Icons.error_outline,
          iconColor: Colors.red,
          contentWidgets: [
            Text("Erro ao carregar lista de amigos.", style: TextStyle(color: textColor)),
          ],
          actions: [
            _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
          ],
        );
      }
    }
  }

  Future<void> _removeFriend(String friendId, String friendName) async {
    if (_currentUser == null || !mounted) return;

    final bool? confirmRemove = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: primaryColor.withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: Text("Remover Amigo", style: TextStyle(color: accentColorBlue)),
          content: Text("Tem certeza que deseja remover $friendName da sua lista de amigos?", style: TextStyle(color: textColor)),
          actions: <Widget>[
            TextButton(
              child: Text("Remover", style: TextStyle(color: Colors.redAccent)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
            TextButton(
              child: Text("Cancelar", style: TextStyle(color: textColor.withOpacity(0.7))),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
          ],
        );
      },
    );

    if (confirmRemove == true) {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 1. Remover da lista de amigos do usuário atual
      DocumentReference currentUserFriendRef = FirebaseFirestore.instance
          .collection('users').doc(_currentUser.uid)
          .collection('friends').doc(friendId);
      batch.delete(currentUserFriendRef);

      // 2. Remover o usuário atual da lista de amigos do amigo removido
      DocumentReference exFriendRef = FirebaseFirestore.instance
          .collection('users').doc(friendId)
          .collection('friends').doc(_currentUser.uid);
      batch.delete(exFriendRef);

      // Decrementar friendCount apenas do usuário atual
      DocumentReference currentUserRef = FirebaseFirestore.instance
          .collection('users').doc(_currentUser.uid);

      batch.update(currentUserRef, {'friendCount': FieldValue.increment(-1)});

      try {
        await batch.commit();
        
        // Tentar decrementar friendCount do ex-amigo - se falhar, não é crítico
        FirebaseFirestore.instance
            .collection('users')
            .doc(friendId)
            .update({'friendCount': FieldValue.increment(-1)})
            .catchError((e) {
          print("Aviso: Não foi possível atualizar friendCount do ex-amigo: $e");
          // Ignorar erro - não é crítico para a funcionalidade
        });
        
        if (mounted) {
          _showStyledDialog(
            context: context,
            titleText: "Amigo Removido",
            icon: Icons.person_remove_outlined,
            iconColor: Colors.grey,
            contentWidgets: [
              Text("$friendName foi removido da sua lista de amigos.", style: TextStyle(color: textColor)),
            ],
            actions: [
              _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
            ],
          );
          _fetchFriends(); // Recarrega a lista de amigos
        }
      } catch (e) {
        print("Erro ao remover amigo: $e");
        if (mounted) {
          _showStyledDialog(
            context: context,
            titleText: "Erro",
            icon: Icons.error_outline,
            iconColor: Colors.red,
            contentWidgets: [
              Text("Erro ao remover amigo. Tente novamente.", style: TextStyle(color: textColor)),
            ],
            actions: [
              _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
            ],
          );
        }
      }
    }
  }
  
  void _navigateToPlayerProfile(String playerId, String playerName) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ViewOtherProfileScreen(userId: playerId, initialPlayerName: playerName,)),
    );
  }

  Widget _buildDialogButton(BuildContext context, String text, VoidCallback onPressed, bool isPrimary) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? accentColorPurple : Colors.grey.shade700,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: isPrimary ? accentColorBlue : Colors.transparent),
        ),
      ),
      child: Text(text.toUpperCase()),
    );
  }

  Future<T?> _showStyledDialog<T>({
    required BuildContext context,
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
        title: Text("Meus Amigos (${_friendsList.length})", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: accentColorBlue),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColorPurple))
          : _friendsList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sentiment_dissatisfied_outlined, size: 80, color: textColor.withOpacity(0.5)),
                      SizedBox(height: 20),
                      Text(
                        "Você ainda não tem amigos.",
                        style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 16),
                      ),
                       SizedBox(height: 10),
                      Text(
                        "Adicione amigos visualizando seus perfis no Ranking!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 13),
                      ),
                    ],
                  )
                )
              : RefreshIndicator(
                  onRefresh: _fetchFriends,
                  color: accentColorPurple,
                  backgroundColor: primaryColor,
                  child: ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemCount: _friendsList.length,
                    itemBuilder: (context, index) {
                      final friend = _friendsList[index];
                      return Card(
                        color: panelBgColor,
                        margin: EdgeInsets.symmetric(vertical: 6.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text(friend.friendName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text("Amigos desde: ${TimeUtils.formatTimestamp(friend.friendshipDate)}", style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12)),
                          trailing: IconButton(
                            icon: Icon(Icons.person_remove_outlined, color: redAccentColor),
                            tooltip: "Remover Amigo",
                            onPressed: () => _removeFriend(friend.friendId, friend.friendName),
                          ),
                          onTap: () => _navigateToPlayerProfile(friend.friendId, friend.friendName),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// Helper para formatar Timestamp (pode ir para um arquivo de utils)
class TimeUtils {
  static String formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}