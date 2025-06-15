// Em lib/screens/view_other_profile_screen.dart
// ignore_for_file: prefer_const_constructors, avoid_print, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math'; // Para pow()
import '../services/email_service.dart';
import '../utils/aura_calculator.dart' as aura_utils;

// CORES (Copie suas constantes de cores para cá ou importe de um arquivo global)
const Color primaryColor = Color(0xFF0A0E21);
const Color accentColorBlue = Color(0xFF40C4FF);
const Color accentColorPurple = Color(0xFF8A2BE2);
const Color textColor = Colors.white;
const Color panelBgColor = Color(0x991D1E33);
const Color greenStatColor = Colors.greenAccent;
const Color yellowWarningColor = Colors.yellowAccent;
const Color prColor = Colors.amberAccent;

const Map<String, Color> itemRankColors = {
  'E': Colors.grey, 'D': Colors.green, 'C': Colors.yellowAccent,
  'B': Color(0xFFADADAD), 'A': Colors.orange, 'S': Colors.redAccent,
  'SS': Colors.pinkAccent, 'SSS': Color(0xFF6F7FFF), 'Global': accentColorPurple,
};

// --- TÍTULOS E SUAS CONDIÇÕES ---
const Map<String, Map<String, dynamic>> availableTitles = {
  'Aspirante': {'condition': 'default', 'bonuses': {}, 'expReward': 0},
  'Iniciante da Força': {'condition': 'FOR >= 25', 'bonuses': {'FOR': 5}, 'expReward': 50},
  'Resistente': {'condition': 'VIT >= 25', 'bonuses': {'VIT': 7}, 'expReward': 50},
  'Veloz': {'condition': 'AGI >= 25', 'bonuses': {'AGI': 8}, 'expReward': 50},
  'Sábio': {'condition': 'INT >= 25', 'bonuses': {'INT': 6}, 'expReward': 50},
  'Observador': {'condition': 'PER >= 25', 'bonuses': {'PER': 10}, 'expReward': 50},
  'Guerreiro': {'condition': 'FOR >= 50', 'bonuses': {'FOR': 10, 'VIT': 5}, 'expReward': 100},
  'Tanque': {'condition': 'VIT >= 50', 'bonuses': {'VIT': 15, 'FOR': 3}, 'expReward': 100},
  'Assassino': {'condition': 'AGI >= 50', 'bonuses': {'AGI': 12, 'PER': 5}, 'expReward': 100},
  'Mago': {'condition': 'INT >= 50', 'bonuses': {'INT': 12, 'MP_MAX_BONUS': 20}, 'expReward': 100},
  'Explorador': {'condition': 'PER >= 50', 'bonuses': {'PER': 15, 'AGI': 3}, 'expReward': 100},
  'Lenda da Força': {'condition': 'FOR >= 100', 'bonuses': {'FOR': 20, 'VIT': 10}, 'expReward': 200},
  'Imortal': {'condition': 'VIT >= 100', 'bonuses': {'VIT': 25, 'HP_MAX_BONUS': 50}, 'expReward': 200},
  'Sombra': {'condition': 'AGI >= 100', 'bonuses': {'AGI': 20, 'PER': 8}, 'expReward': 200},
  'Arqui-Mago': {'condition': 'INT >= 100', 'bonuses': {'INT': 22, 'MP_MAX_BONUS': 40}, 'expReward': 200},
  'Onividente': {'condition': 'PER >= 100', 'bonuses': {'PER': 25, 'INT': 5}, 'expReward': 200},
};

// --- CLASSES E SUAS CONDIÇÕES ---
const Map<String, Map<String, dynamic>> availableClasses = {
  'Nenhuma': {'condition': 'default', 'bonuses': {}},
  // Classes Básicas (Nível 3)
  'Guerreiro': {'condition': 'level >= 3', 'baseBonuses': {'FOR': 8, 'VIT': 5}, 'scalingBonuses': {'FOR': 2, 'VIT': 1}},
  'Mago': {'condition': 'level >= 3', 'baseBonuses': {'INT': 8, 'MP_MAX_BONUS': 15}, 'scalingBonuses': {'INT': 2, 'MP_MAX_BONUS': 3}},
  'Arqueiro': {'condition': 'level >= 3', 'baseBonuses': {'AGI': 7, 'PER': 5}, 'scalingBonuses': {'AGI': 2, 'PER': 1}},
  // Classes Intermediárias (Nível 6)
  'Paladino': {'condition': 'level >= 6', 'baseBonuses': {'FOR': 6, 'VIT': 10}, 'scalingBonuses': {'FOR': 1, 'VIT': 2}},
  'Assassino': {'condition': 'level >= 6', 'baseBonuses': {'AGI': 12, 'PER': 3}, 'scalingBonuses': {'AGI': 3, 'PER': 1}},
  'Necromante': {'condition': 'level >= 6', 'baseBonuses': {'INT': 10, 'PER': 4}, 'scalingBonuses': {'INT': 2, 'PER': 1}},
  // Classes Avançadas (Nível 9)
  'Berserker': {'condition': 'level >= 9', 'baseBonuses': {'FOR': 15, 'AGI': 5}, 'scalingBonuses': {'FOR': 3, 'AGI': 1}},
  'Arcano': {'condition': 'level >= 9', 'baseBonuses': {'INT': 15, 'MP_MAX_BONUS': 25}, 'scalingBonuses': {'INT': 3, 'MP_MAX_BONUS': 4}},
  'Ranger': {'condition': 'level >= 9', 'baseBonuses': {'AGI': 8, 'PER': 8}, 'scalingBonuses': {'AGI': 2, 'PER': 2}},
  // Classes Legendárias (Nível 12)
  'Lorde da Guerra': {'condition': 'level >= 12', 'baseBonuses': {'FOR': 20, 'VIT': 15}, 'scalingBonuses': {'FOR': 4, 'VIT': 2}},
  'Mestre Arcano': {'condition': 'level >= 12', 'baseBonuses': {'INT': 20, 'MP_MAX_BONUS': 35}, 'scalingBonuses': {'INT': 4, 'MP_MAX_BONUS': 5}},
  'Sombra Letal': {'condition': 'level >= 12', 'baseBonuses': {'AGI': 18, 'PER': 12}, 'scalingBonuses': {'AGI': 3, 'PER': 2}},
};

// Funções auxiliares para calcular bônus
Map<String, int> _getTitleBonuses(String title) {
  final titleData = availableTitles[title];
  if (titleData == null) return {};
  return Map<String, int>.from(titleData['bonuses'] ?? {});
}

Map<String, int> _calculateClassBonuses(String className, int level) {
  if (className == 'Nenhuma' || !availableClasses.containsKey(className)) {
    return {};
  }
  
  final classData = availableClasses[className]!;
  final baseBonuses = Map<String, int>.from(classData['baseBonuses'] ?? {});
  final scalingBonuses = Map<String, int>.from(classData['scalingBonuses'] ?? {});
  
  Map<String, int> totalBonuses = {};
  
  // Adicionar bônus base
  for (String stat in baseBonuses.keys) {
    totalBonuses[stat] = baseBonuses[stat]!;
  }
  
  // Adicionar bônus escalonado baseado no nível (a partir do nível de desbloqueio)
  final condition = classData['condition'] as String;
  final minLevel = int.tryParse(condition.split(' ').last) ?? 1;
  final levelsAboveMin = level - minLevel;
  
  if (levelsAboveMin > 0) {
    for (String stat in scalingBonuses.keys) {
      totalBonuses[stat] = (totalBonuses[stat] ?? 0) + (scalingBonuses[stat]! * levelsAboveMin);
    }
  }
  
  return totalBonuses;
}

// Modelo de Item (Defina ou importe)
class Item {
  final String id; final String name; final String slotType; final String rank;
  final DateTime dateAcquired; final IconData icon; bool isNew;
  final Map<String, int> statBonuses;
  Item({ required this.id, required this.name, required this.slotType, required this.rank,
    required this.dateAcquired, required this.icon, this.isNew = false, this.statBonuses = const {},});
}

// Placeholders para widgets que podem vir de outros arquivos
class EquipmentSlotWidget extends StatelessWidget {
  final String slotName; final IconData placeholderIcon; final bool isEquipped; final String? itemName; final Color? itemRankColor;
  final VoidCallback? onTap;
  const EquipmentSlotWidget({
    required this.slotName, required this.placeholderIcon, 
    this.isEquipped = false, this.itemName, this.itemRankColor,
    this.onTap,
    super.key, 
    bool? hasNewItem // Não relevante para visualização de outros
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50, width: double.infinity, margin: const EdgeInsets.symmetric(vertical: 2.0),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: panelBgColor.withOpacity(0.5), 
          borderRadius: BorderRadius.circular(8.0), 
          border: Border.all(color: accentColorBlue.withOpacity(0.3))
        ),
        child: Row(children: [
          Icon(placeholderIcon, color: itemRankColor ?? accentColorBlue.withOpacity(0.7), size: 18),
          const SizedBox(width: 6),
          Expanded(child: Text(itemName ?? slotName, style: TextStyle(color: itemRankColor ?? textColor.withOpacity(0.8), fontSize: 10, fontWeight: itemName != null ? FontWeight.bold : FontWeight.normal ), overflow: TextOverflow.ellipsis,)),
          if (isEquipped) Icon(Icons.check_circle, color: greenStatColor.withOpacity(0.9), size: 12),
          if (isEquipped && onTap != null) const SizedBox(width: 4),
          if (isEquipped && onTap != null) Icon(Icons.info_outline, color: accentColorBlue.withOpacity(0.7), size: 12),
        ],),
      ),
    );
  }
}

class ViewOtherProfileScreen extends StatefulWidget {
  final String userId;
  final String? initialPlayerName; // Opcional, para exibir enquanto carrega

  const ViewOtherProfileScreen({
    required this.userId,
    this.initialPlayerName,
    super.key,
  });

  @override
  State<ViewOtherProfileScreen> createState() => _ViewOtherProfileScreenState();
}

class _ViewOtherProfileScreenState extends State<ViewOtherProfileScreen> {
  bool _isLoadingData = true;
  bool _isProcessingFriendAction = false;
  bool _friendRequestSent = false;
  bool _isFriend = false;
  String _playerName = "Carregando...";
  int _level = 1;
  String _currentJob = "Nenhuma";
  String _currentTitle = "Aspirante";
  double _hp = 0; // Inicializa com 0 ou valores padrão
  double _maxHp = 100;
  double _mp = 0;
  double _maxMp = 50;
  Map<String, int> _baseStats = {};
  Map<String, int> _bonusStats = {};
  double _currentExp = 0;
  int _expToNextLevel = 100;
  Map<String, String?> _equippedItemsMap = {}; // Para IDs dos itens equipados
  Map<String, Item> _loadedEquippedItems = {}; // Para os objetos Item detalhados
  int _calculatedAura = 0;
  String? _profileImageUrl;
  double _height = 0;
  double _weight = 0;
  String _biography = "";
  Map<String, bool> _completedAchievements = {};

  @override
  void initState() {
    super.initState();
    _playerName = widget.initialPlayerName ?? "Carregando...";
    _loadUserProfileData();
    _checkFriendshipStatus(); // NOVO: Verifica status de amizade/pedido
  }

  int getExpForNextLevel(int currentLvl) {
    if (currentLvl <= 0) return 100;
    return (100 * pow(1.35, currentLvl - 1)).round();
  }

  Future<void> _calculateDisplayData() async { // Tornar assíncrono para buscar itens
    if (!mounted) return;

    Map<String, int> currentBonusStats = {'FOR': 0, 'VIT': 0, 'AGI': 0, 'INT': 0, 'PER': 0};
    int bonusMaxMpFromItems = 0;
    int bonusMaxHpFromItems = 0;
    int bonusMaxMpFromTitleClass = 0;
    int bonusMaxHpFromTitleClass = 0;
    Map<String, Item> tempLoadedEquippedItems = {};

    // Usar um Future.wait para buscar todos os itens equipados em paralelo
    List<Future<void>> itemFetches = [];

    _equippedItemsMap.forEach((slot, itemId) {
      if (itemId != null) {
        itemFetches.add(Future<void>(() async {
          try {
            DocumentSnapshot itemDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .collection('inventory')
                .doc(itemId)
                .get();

            if (itemDoc.exists && itemDoc.data() != null) {
              Map<String, dynamic> itemData = itemDoc.data() as Map<String, dynamic>;
              // Criar um objeto Item a partir dos dados do Firestore
              // Você precisará ajustar isso para mapear seus campos do Firestore para o seu modelo Item
              Item item = Item(
                id: itemDoc.id,
                name: itemData['name'] ?? 'Item Desconhecido',
                slotType: itemData['type'] ?? '',
                rank: itemData['rank'] ?? 'E',
                dateAcquired: (itemData['acquiredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                icon: (itemData['iconCodePoint'] != null && itemData['iconFontFamily'] != null)
                    ? _getItemIconFromData(itemData['iconCodePoint'] as int, itemData['iconFontFamily'] as String)
                    : Icons.help_outline,
                statBonuses: Map<String, int>.from(itemData['statBonuses'] ?? {}),
              );
              tempLoadedEquippedItems[slot] = item;

              Map<String, dynamic>.from(item.statBonuses).forEach((statKey, bonusValue) {
                if (currentBonusStats.containsKey(statKey)) {
                  currentBonusStats[statKey] = (currentBonusStats[statKey] ?? 0) + (bonusValue as int);
                } else if (statKey == 'MP_MAX_BONUS') {
                  bonusMaxMpFromItems += (bonusValue as int);
                } else if (statKey == 'HP_MAX_BONUS') {
                  bonusMaxHpFromItems += (bonusValue as int);
                }
              });
            }
          } catch (e) {
            print("Erro ao buscar item $itemId do Firestore (ViewOtherProfile): $e");
          }
        }));
      }
    });

    await Future.wait(itemFetches);

    // Calcular bônus de título (em porcentagem)
    Map<String, int> titleBonuses = {};
    Map<String, int> rawTitleBonuses = _getTitleBonuses(_currentTitle);
    rawTitleBonuses.forEach((statKey, bonusPercentage) {
      if (currentBonusStats.containsKey(statKey)) {
        int baseValue = _baseStats[statKey] ?? 0;
        int calculatedBonus = ((baseValue * bonusPercentage) / 100).round();
        titleBonuses[statKey] = calculatedBonus;
        currentBonusStats[statKey] = (currentBonusStats[statKey] ?? 0) + calculatedBonus;
      } else if (statKey == 'MP_MAX_BONUS') {
        bonusMaxMpFromTitleClass += bonusPercentage;
      } else if (statKey == 'HP_MAX_BONUS') {
        bonusMaxHpFromTitleClass += bonusPercentage;
      }
    });

    // Calcular bônus de classe (em porcentagem)
    Map<String, int> classBonuses = {};
    Map<String, int> rawClassBonuses = _calculateClassBonuses(_currentJob, _level);
    rawClassBonuses.forEach((statKey, bonusPercentage) {
      if (currentBonusStats.containsKey(statKey)) {
        int baseValue = _baseStats[statKey] ?? 0;
        int calculatedBonus = ((baseValue * bonusPercentage) / 100).round();
        classBonuses[statKey] = calculatedBonus;
        currentBonusStats[statKey] = (currentBonusStats[statKey] ?? 0) + calculatedBonus;
      } else if (statKey == 'MP_MAX_BONUS') {
        bonusMaxMpFromTitleClass += bonusPercentage;
      } else if (statKey == 'HP_MAX_BONUS') {
        bonusMaxHpFromTitleClass += bonusPercentage;
      }
    });
    
    // Atualiza o estado com os bônus e itens carregados
    _bonusStats = currentBonusStats;
    _loadedEquippedItems = tempLoadedEquippedItems;
    
    int totalVit = (_baseStats['VIT'] ?? 0) + (_bonusStats['VIT'] ?? 0);
    int totalInt = (_baseStats['INT'] ?? 0) + (_bonusStats['INT'] ?? 0);

    _maxHp = (totalVit * 10).toDouble() + bonusMaxHpFromItems + bonusMaxHpFromTitleClass;
    _hp = _maxHp; // Sempre manter HP completo
    if (_maxHp <= 0 && totalVit > 0) _maxHp = 10;

    _maxMp = (totalInt * 5).toDouble() + bonusMaxMpFromItems + bonusMaxMpFromTitleClass;
    _mp = _maxMp; // Sempre manter MP completo
    if (_maxMp <= 0 && totalInt > 0) _maxMp = 5;

    // Usar função centralizada para calcular aura total (incluindo conquistas)
    _calculatedAura = aura_utils.calculateTotalAura(
      baseStats: _baseStats,
      bonusStats: _bonusStats,
      currentTitle: _currentTitle,
      currentJob: _currentJob,
      level: _level,
      completedAchievements: _completedAchievements,
    );
  }

  Future<void> _loadUserProfileData() async {
    if (!mounted) return;
    setState(() { _isLoadingData = true; });
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _playerName = data['playerName'] ?? "Jogador Desconhecido";
          _level = data['level'] ?? 1;
          _currentJob = data['job'] ?? 'Nenhuma';
          _currentTitle = data['title'] ?? 'Aspirante';
          _baseStats = Map<String, int>.from(Map<String, dynamic>.from(data['stats'] ?? {}));
          // _bonusStats será recalculado em _calculateDisplayData com base nos itens
          _currentExp = (data['exp'] ?? 0.0).toDouble();
          _expToNextLevel = getExpForNextLevel(_level);
          _hp = (data['currentHP'] ?? 100.0).toDouble(); 
          _mp = (data['currentMP'] ?? 50.0).toDouble();
          _equippedItemsMap = Map<String, String?>.from(data['equippedItems'] ?? {});
          _profileImageUrl = data['profileImageUrl'] as String?;
          _height = (data['height'] ?? 0.0).toDouble();
          _weight = (data['weight'] ?? 0.0).toDouble();
          _biography = data['biography'] ?? "";
          _completedAchievements = Map<String, bool>.from(data['completedAchievements'] ?? {});
        });
        await _calculateDisplayData(); // Chamar _calculateDisplayData após setState inicial
      } else {
        print("Documento do usuário ${widget.userId} não encontrado.");
        if (mounted) setState(() { _playerName = "Perfil Não Encontrado"; });
      }
    } catch (e) {
      print("Erro ao carregar perfil de outro usuário: $e");
      if (mounted) setState(() { _playerName = "Erro ao Carregar"; });
    } finally {
      if (mounted) { setState(() { _isLoadingData = false; });}
    }
  }

  Future<void> _checkFriendshipStatus() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || !mounted) return;

    setState(() { _isProcessingFriendAction = true; });

    try {
      // 1. Verificar se já são amigos
      DocumentSnapshot friendDoc = await FirebaseFirestore.instance
          .collection('users').doc(currentUser.uid)
          .collection('friends').doc(widget.userId)
          .get();
      
      if (friendDoc.exists) {
        if (mounted) setState(() { _isFriend = true; });
        return;
      }

      // 2. Verificar se um pedido já foi enviado PARA este usuário PELO usuário atual
      DocumentSnapshot requestSentDoc = await FirebaseFirestore.instance
          .collection('users').doc(widget.userId) // Documento do perfil visualizado
          .collection('friendRequestsReceived') // Subcoleção de pedidos recebidos por ele
          .doc(currentUser.uid) // Documento com ID do usuário atual (remetente)
          .get();

      if (requestSentDoc.exists) {
        if (mounted) setState(() { _friendRequestSent = true; });
      }
    } catch (e) {
      print("Erro ao verificar status de amizade: $e");
    } finally {
      if (mounted) setState(() { _isProcessingFriendAction = false; });
    }
  }

  Future<void> _sendFriendRequest() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        _showStyledDialog(
          passedContext: context,
          titleText: "Erro",
          icon: Icons.error_outline,
          iconColor: Colors.redAccent,
          contentWidgets: [
            Text(
              "Você precisa estar logado para adicionar amigos.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: textColor, fontSize: 16)
            )
          ],
          actions: [
            _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true)
          ],
        );
      }
      return;
    }

    if (currentUser.uid == widget.userId) {
      if (mounted) {
        _showStyledDialog(
          passedContext: context,
          titleText: "Aviso",
          icon: Icons.warning_amber_rounded,
          iconColor: yellowWarningColor,
          contentWidgets: [
            Text(
              "Você não pode adicionar a si mesmo como amigo.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: textColor, fontSize: 16)
            )
          ],
          actions: [
            _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true)
          ],
        );
      }
      return;
    }

    // Verificar se o pedido já foi enviado (lógica já implementada em _checkFriendshipStatus e usada no botão)
    if (_friendRequestSent || _isFriend) { // _isFriend é mockado como false, mas a checagem futura será real
       if (mounted) {
        _showStyledDialog(
          passedContext: context,
          titleText: "Aviso",
          icon: Icons.warning_amber_rounded,
          iconColor: yellowWarningColor,
          contentWidgets: [
            Text(
              _isFriend ? "Vocês já são amigos!" : "Pedido de amizade já enviado.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: textColor, fontSize: 16)
            )
          ],
          actions: [
            _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true)
          ],
        );
      }
      return;
    }

    setState(() { _isProcessingFriendAction = true; });

    try {
      // Buscar nome e imagem do usuário logado no Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      String senderName = "Jogador";
      String? profileImageUrl;
      
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        senderName = userData['playerName'] ?? currentUser.displayName ?? "Jogador";
        profileImageUrl = userData['profileImageUrl'];
      } else {
        senderName = currentUser.displayName ?? "Jogador";
      }
      
      // Adicionar o pedido de amizade na subcoleção 'friendRequestsReceived' do usuário alvo
      await FirebaseFirestore.instance
          .collection('users').doc(widget.userId)
          .collection('friendRequestsReceived').doc(currentUser.uid)
          .set({
            'senderId': currentUser.uid,
            'senderName': senderName,
            'profileImageUrl': profileImageUrl,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'pending',
          });

      if (mounted) {
        setState(() { _friendRequestSent = true; });
        _showStyledDialog(
          passedContext: context,
          titleText: "Sucesso",
          icon: Icons.check_circle_rounded,
          iconColor: Colors.green,
          contentWidgets: [
            Text(
              "Pedido de amizade enviado para $_playerName!",
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
      print("Erro ao enviar pedido de amizade: $e");
      if (mounted) {
         _showStyledDialog(
          passedContext: context,
          titleText: "Erro",
          icon: Icons.error_outline,
          iconColor: Colors.redAccent,
          contentWidgets: [
            Text(
              "Erro ao enviar pedido de amizade. Tente novamente.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: textColor, fontSize: 16)
            )
          ],
          actions: [
            _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true)
          ],
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isProcessingFriendAction = false; });
      }
    }
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
  
  void _showItemDetails(Item item) {
    List<Widget> attributeWidgets = [];
    
    if (item.statBonuses.isNotEmpty) {
      item.statBonuses.forEach((stat, bonus) {
        Color statColor = Colors.green;
        String statName = stat;
        
        // Mapear nomes dos atributos
        switch (stat) {
          case 'FOR':
            statName = 'Força';
            statColor = Colors.red;
            break;
          case 'VIT':
            statName = 'Vitalidade';
            statColor = Colors.green;
            break;
          case 'AGI':
            statName = 'Agilidade';
            statColor = Colors.blue;
            break;
          case 'INT':
            statName = 'Inteligência';
            statColor = Colors.purple;
            break;
          case 'PER':
            statName = 'Percepção';
            statColor = Colors.amber;
            break;
          case 'HP_MAX_BONUS':
            statName = 'HP Máximo';
            statColor = Colors.redAccent;
            break;
          case 'MP_MAX_BONUS':
            statName = 'MP Máximo';
            statColor = Colors.blueAccent;
            break;
        }
        
        attributeWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, color: statColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  "$statName: +$bonus",
                  style: TextStyle(color: statColor, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      });
    } else {
      attributeWidgets.add(
        Text(
          "Nenhum atributo especial",
          style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14, fontStyle: FontStyle.italic),
        ),
      );
    }

    _showStyledDialog(
      passedContext: context,
      titleText: "Detalhes do Item",
      icon: Icons.info_outline,
      iconColor: itemRankColors[item.rank] ?? accentColorBlue,
      contentWidgets: [
        Center(
          child: Column(
            children: [
              Icon(item.icon, color: itemRankColors[item.rank] ?? accentColorBlue, size: 48),
              const SizedBox(height: 12),
              Text(
                item.name,
                style: TextStyle(
                  color: itemRankColors[item.rank] ?? textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: (itemRankColors[item.rank] ?? accentColorBlue).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: itemRankColors[item.rank] ?? accentColorBlue),
                ),
                child: Text(
                  "Rank ${item.rank}",
                  style: TextStyle(
                    color: itemRankColors[item.rank] ?? accentColorBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Tipo: ${item.slotType}",
                style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 12),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: panelBgColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColorBlue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ATRIBUTOS:",
                      style: TextStyle(
                        color: accentColorBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...attributeWidgets,
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      actions: [
        _buildDialogButton(context, "Fechar", () => Navigator.of(context).pop(), true)
      ],
    );
  }

  Future<void> _sendReportEmail(String reason) async {
    try {
      // Mostrar dialog de carregamento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: accentColorPurple),
        ),
      );

      // Buscar o nome do usuário que está denunciando
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Navigator.of(context).pop(); // Fechar loading
        return;
      }
      
      DocumentSnapshot reporterDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
          
      String reporterName = "Usuário Desconhecido";
      if (reporterDoc.exists && reporterDoc.data() != null) {
        final data = reporterDoc.data() as Map<String, dynamic>;
        reporterName = data['playerName'] ?? currentUser.displayName ?? "Usuário Desconhecido";
      }

      // Enviar e-mail usando o EmailJS
      bool emailSent = await EmailService.sendReportEmail(
        reason: reason,
        reportedPlayerName: _playerName,
        reportedPlayerId: widget.userId,
        reporterName: reporterName,
        reporterId: currentUser.uid,
      );

      // Fechar loading
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        if (emailSent) {
          _showStyledDialog(
            passedContext: context,
            titleText: "Denúncia Enviada",
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            contentWidgets: [
              Text(
                "Sua denúncia foi enviada com sucesso. Nossa equipe irá analisar o caso.",
                style: TextStyle(color: textColor),
                textAlign: TextAlign.center,
              ),
            ],
            actions: [
              _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
            ],
          );
        } else {
          _showStyledDialog(
            passedContext: context,
            titleText: "Erro",
            icon: Icons.error_outline,
            iconColor: Colors.red,
            contentWidgets: [
              Text(
                "Erro ao enviar denúncia. Tente novamente mais tarde.",
                style: TextStyle(color: textColor),
                textAlign: TextAlign.center,
              ),
            ],
            actions: [
              _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
            ],
          );
        }
      }
    } catch (e) {
      // Erro ao processar denúncia
      
      // Fechar loading se ainda estiver aberto
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        _showStyledDialog(
          passedContext: context,
          titleText: "Erro",
          icon: Icons.error_outline,
          iconColor: Colors.red,
          contentWidgets: [
            Text(
              "Erro ao processar denúncia. Verifique sua conexão e tente novamente.",
              style: TextStyle(color: textColor),
              textAlign: TextAlign.center,
            ),
          ],
          actions: [
            _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
          ],
        );
      }
    }
  }

  void _reportUser() {
    _showStyledDialog(
      passedContext: context,
      titleText: "Denunciar Jogador",
      icon: Icons.report_problem_outlined,
      iconColor: Colors.orangeAccent,
      contentWidgets: [
        Text("Selecione o motivo da denúncia para $_playerName:", style: TextStyle(color: textColor)),
        SizedBox(height: 10),
        ListTile(
          title: Text("Nome Inadequado", style: TextStyle(color: textColor)), 
          onTap: () {
            Navigator.of(context).pop();
            _sendReportEmail("Nome Inadequado");
          }
        ),
        ListTile(
          title: Text("Uso de Cheats", style: TextStyle(color: textColor)), 
          onTap: () {
            Navigator.of(context).pop();
            _sendReportEmail("Uso de Cheats");
          }
        ),
        ListTile(
          title: Text("Foto de Perfil Inadequada", style: TextStyle(color: textColor)), 
          onTap: () {
            Navigator.of(context).pop();
            _sendReportEmail("Foto de Perfil Inadequada");
          }
        ),
        ListTile(
          title: Text("Biografia Inadequada", style: TextStyle(color: textColor)), 
          onTap: () {
            Navigator.of(context).pop();
            _sendReportEmail("Biografia Inadequada");
          }
        ),
        ListTile(
          title: Text("Outro", style: TextStyle(color: textColor)), 
          onTap: () {
            Navigator.of(context).pop();
            _sendReportEmail("Outro motivo");
          }
        ),
      ],
      actions: [
        _buildDialogButton(context, "Cancelar", () => Navigator.of(context).pop(), false)
      ]
    );
  }

  IconData _getItemIconFromData(int iconCodePoint, String fontFamily) {
    // Mapeamento de códigos comuns para ícones constantes do Material Design
    switch (iconCodePoint) {
      case 0xe3c9: return Icons.ac_unit; // ac_unit (gelo/arma fria)
      case 0xe148: return Icons.star; // star
      case 0xe153: return Icons.shield; // shield
      case 0xe85e: return Icons.group; // group
      case 0xe88e: return Icons.home; // home
      case 0xe3e7: return Icons.autorenew; // autorenew (espada)
      case 0xe869: return Icons.military_tech; // military_tech
      case 0xe86c: return Icons.favorite; // favorite
      case 0xe25d: return Icons.health_and_safety; // health_and_safety (poção)
      case 0xe7fd: return Icons.whatshot; // whatshot (fogo)
      case 0xe8d2: return Icons.castle; // castle
      case 0xe1b2: return Icons.spa; // spa
      case 0xf02e2: return Icons.tonality; // tonality (como alternativa)
      default: 
        // Para ícones não mapeados, usar um ícone padrão baseado no tipo
        return Icons.category;
    }
  }

  Widget _buildReadOnlyStatRow(IconData icon, String labelKey, int baseValue, int bonusValue) {
    int totalValue = baseValue + bonusValue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(children: [
        Icon(icon, color: accentColorBlue, size: 18), 
        const SizedBox(width: 8),
        SizedBox(
          width: 40, 
          child: Text(
            "$labelKey: ", 
            style: const TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          "$totalValue", 
          style: TextStyle(color: bonusValue > 0 ? greenStatColor : textColor, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        if (bonusValue != 0) 
          Text(
            " ($baseValue ${bonusValue > 0 ? '+' : ''}$bonusValue)", 
            style: TextStyle(color: bonusValue > 0 ? greenStatColor.withOpacity(0.8) : Colors.redAccent[100]?.withOpacity(0.8), fontSize: 11),
          ),
      ],),
    );
  }

  Widget _buildReadOnlyProgressBar(String label, double value, double maxValue, Color barColor) {
    final double percentage = (maxValue > 0 && value >= 0) ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2), // Aumentado espaço
        Stack(children: [
          Container(height: 8, decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(4))), // Barra mais grossa
          FractionallySizedBox(widthFactor: percentage, child: Container(height: 8, decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(4), boxShadow: [BoxShadow(color: barColor.withOpacity(0.5), blurRadius: 3.0, spreadRadius: 0.5)]))),
        ]),
      ]),
    );
  }

  Widget _buildReadOnlyEquipmentColumn({required bool isLeft}) {
    final List<Map<String, dynamic>> slotDefinitions = isLeft
        ? [ {'name': 'Cabeça', 'icon': Icons.account_circle_outlined, 'type': 'Cabeça'},
            {'name': 'Peitoral', 'icon': Icons.shield_outlined, 'type': 'Peitoral'},
            {'name': 'Mão Direita', 'icon': Icons.pan_tool_alt_outlined, 'type': 'Mão Direita'},
            {'name': 'Pernas', 'icon': Icons.accessibility_new_outlined, 'type': 'Pernas'},
            {'name': 'Pés', 'icon': Icons.do_not_step, 'type': 'Pés'},
            {'name': 'Acessório E.', 'icon': Icons.star_border_outlined, 'type': 'Acessório E.'}, ]
        : [ {'name': 'Orelhas', 'icon': Icons.earbuds_outlined, 'type': 'Orelhas'},
            {'name': 'Colar', 'icon': Icons.circle_outlined, 'type': 'Colar'},
            {'name': 'Mão Esquerda', 'icon': Icons.pan_tool_alt_outlined, 'type': 'Mão Esquerda'},
            {'name': 'Rosto', 'icon': Icons.face_retouching_natural_outlined, 'type': 'Rosto'},
            {'name': 'Bracelete', 'icon': Icons.watch_later_outlined, 'type': 'Bracelete'},
            {'name': 'Acessório D.', 'icon': Icons.star_border_outlined, 'type': 'Acessório D.'},];
    
    List<Widget> displayedSlots = [];
    for (var slotDef in slotDefinitions) {
        String slotType = slotDef['type'] as String;
        Item? equippedItem = _loadedEquippedItems[slotType];
        displayedSlots.add(
            EquipmentSlotWidget(
            slotName: equippedItem?.name ?? slotDef['name'],
            placeholderIcon: equippedItem?.icon ?? slotDef['icon'],
            isEquipped: equippedItem != null,
            itemRankColor: equippedItem != null ? itemRankColors[equippedItem.rank] : null,
            onTap: equippedItem != null ? () => _showItemDetails(equippedItem) : null,
            )
        );
    }
    return SizedBox(width: 100, child: Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: displayedSlots));
  }

  // --- MÉTODO BUILD PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(backgroundColor: primaryColor, appBar: AppBar(title: Text(widget.initialPlayerName ?? "Carregando Perfil..."), backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: accentColorBlue)), body: Center(child: CircularProgressIndicator(color: accentColorPurple)));
    }
    if (_playerName == "Perfil Não Encontrado" || _playerName == "Erro ao Carregar") {
       return Scaffold(backgroundColor: primaryColor, appBar: AppBar(title: Text(_playerName), backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: accentColorBlue), leading: IconButton(icon: Icon(Icons.arrow_back_ios_new), onPressed: ()=> Navigator.of(context).pop()),), body: Center(child: Text(_playerName, style: TextStyle(color:Colors.redAccent, fontSize: 18))));
    }

    User? currentUser = FirebaseAuth.instance.currentUser;
    bool canInteract = currentUser != null && currentUser.uid != widget.userId;

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Text(_playerName, style: TextStyle(color: accentColorBlue, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.0)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: accentColorBlue), onPressed: () => Navigator.of(context).pop()),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(8.0), padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration( borderRadius: BorderRadius.circular(10.0),
                gradient: LinearGradient( colors: [accentColorBlue.withOpacity(0.6), accentColorPurple.withOpacity(0.6)], begin: Alignment.topLeft, end: Alignment.bottomRight,),
                boxShadow: [ BoxShadow( color: accentColorPurple.withOpacity(0.3), blurRadius: 6.0,) ] ),
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration( color: primaryColor.withOpacity(0.95), borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: accentColorBlue.withOpacity(0.4))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Seção de Informações do Jogador (Nível, Nome, Classe, Título)
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Text("$_level", style: TextStyle( color: accentColorBlue, fontSize: 44, fontWeight: FontWeight.bold, shadows: [Shadow(color: accentColorBlue.withOpacity(0.5), blurRadius: 7.0)],)),
                      const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            Text(_playerName.toUpperCase(), style: TextStyle(color: accentColorBlue, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            Text("CLASSE: $_currentJob", style: const TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500)),
                            Text("TÍTULO: $_currentTitle", style: const TextStyle(color: textColor, fontSize: 10, fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis,),],))
                  ]),
                  const SizedBox(height: 10),
                  // Imagem do Perfil e Informações Físicas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: accentColorBlue.withOpacity(0.5), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: accentColorPurple.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _profileImageUrl != null
                              ? Image.network(
                                  _profileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.person,
                                    size: 40,
                                    color: accentColorBlue.withOpacity(0.7),
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 40,
                                  color: accentColorBlue.withOpacity(0.7),
                                ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.height, color: accentColorBlue, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                "Altura: ${(_height * 100).toInt()}cm",
                                style: TextStyle(color: textColor, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.monitor_weight_outlined, color: accentColorBlue, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                "Peso: ${_weight.toStringAsFixed(1)}kg",
                                style: TextStyle(color: textColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Biografia
                  if (_biography.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: panelBgColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accentColorPurple.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.person_outline, color: accentColorPurple, size: 16),
                              SizedBox(width: 6),
                              Text(
                                "BIOGRAFIA",
                                style: TextStyle(
                                  color: accentColorPurple,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _biography,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 5),
                  _buildReadOnlyProgressBar("XP", _currentExp, _expToNextLevel.toDouble(), Colors.lightGreenAccent.shade700),
                  Padding(padding: const EdgeInsets.only(left: 2.0, bottom: 4.0, top:1), child: Text("${_currentExp.toInt()}/${_expToNextLevel.toInt()} EXP", style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 10))),
                  
                  Divider(color: accentColorBlue.withOpacity(0.3), height: 10, thickness: 0.3),
                  _buildReadOnlyProgressBar("HP", _hp, _maxHp, Colors.redAccent),
                  Padding(padding: const EdgeInsets.only(left: 2.0, bottom: 4.0, top:1), child: Text("${_hp.toInt()}/${_maxHp.toInt()} HP", style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 10))),
                  _buildReadOnlyProgressBar("MP", _mp, _maxMp, Colors.blueAccent),
                  Padding(padding: const EdgeInsets.only(left: 2.0, bottom: 4.0, top:1), child: Text("${_mp.toInt()}/${_maxMp.toInt()} MP", style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 10))),
                  
                  Divider(color: accentColorBlue.withOpacity(0.3), height: 10, thickness: 0.3),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.whatshot_rounded, color: prColor, size: 22), const SizedBox(width: 8),
                        Text("AURA TOTAL: ", style: TextStyle(color: accentColorBlue, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        Text("$_calculatedAura", style: TextStyle(color: prColor, fontSize: 18, fontWeight: FontWeight.bold)),],),),),
                  Divider(color: accentColorBlue.withOpacity(0.3), height: 10, thickness: 0.3),

                  IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      _buildReadOnlyStatRow(Icons.fitness_center, "FOR", _baseStats['FOR'] ?? 0, _bonusStats['FOR'] ?? 0),
                      _buildReadOnlyStatRow(Icons.directions_run, "AGI", _baseStats['AGI'] ?? 0, _bonusStats['AGI'] ?? 0),
                      _buildReadOnlyStatRow(Icons.visibility, "PER", _baseStats['PER'] ?? 0, _bonusStats['PER'] ?? 0),
                    ],)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      _buildReadOnlyStatRow(Icons.favorite, "VIT", _baseStats['VIT'] ?? 0, _bonusStats['VIT'] ?? 0),
                      _buildReadOnlyStatRow(Icons.psychology, "INT", _baseStats['INT'] ?? 0, _bonusStats['INT'] ?? 0),
                      // Não mostrar "Pontos Disponíveis" para outros jogadores
                    ],)),
                  ],)),
                  
                  const SizedBox(height: 15),
                  const Text("EQUIPAMENTOS", style: TextStyle(color: accentColorBlue, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _buildReadOnlyEquipmentColumn(isLeft: true),
                        const Spacer(),
                        _buildReadOnlyEquipmentColumn(isLeft: false),
                      ],),),
                  const SizedBox(height: 20),
                  if (canInteract) // Só mostra botões se não for o perfil do próprio usuário
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(
                              _isFriend ? Icons.people_alt_rounded :
                              _friendRequestSent ? Icons.hourglass_top_rounded :
                              Icons.person_add_rounded,
                              size: 18
                            ),
                            label: Text(
                              _isFriend ? "Amigos" :
                              _friendRequestSent ? "Solicitação Enviada" :
                              "Adicionar Amigo"
                            ),
                            onPressed: _isProcessingFriendAction ? null : _sendFriendRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _friendRequestSent || _isFriend ? Colors.grey.shade700 : accentColorBlue.withOpacity(0.8),
                              foregroundColor: textColor,
                              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10)
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: Icon(Icons.report_gmailerrorred_rounded, size: 18),
                            label: Text("Denunciar"),
                            onPressed: _reportUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent.withOpacity(0.8),
                              foregroundColor: textColor,
                              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10)
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}