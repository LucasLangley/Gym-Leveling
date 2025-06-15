// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

// Cores do aplicativo (extraídas de profile_screen.dart para consistência)
const Color primaryColor = Color(0xFF0A0E21);
const Color accentColorBlue = Color(0xFF40C4FF);
const Color accentColorPurple = Color(0xFF8A2BE2);
const Color textColor = Colors.white;
const Color panelBgColor = Color(0x991D1E33);

// Cores para os ranks
const Map<String, Color> itemRankColors = {
  'E': Colors.grey,
  'D': Colors.green,
  'C': Colors.yellowAccent,
  'B': Color(0xFFADADAD),
  'A': Colors.orange,
  'S': Colors.redAccent,
  'SS': Colors.pinkAccent,
  'SSS': Color(0xFF6F7FFF),
  'Global': Color(0xFF8A2BE2),
};

class ItemRouletteScreen extends StatefulWidget {
  const ItemRouletteScreen({super.key});

  @override
  State<ItemRouletteScreen> createState() => _ItemRouletteScreenState();
}

class _ItemRouletteScreenState extends State<ItemRouletteScreen>
    with TickerProviderStateMixin {
  final GlobalKey<FlipCardState> _cardKey = GlobalKey<FlipCardState>();
  bool _isSpinning = false;
  String _selectedItemType = 'Cabeça';
  int _userCoins = 0;
  final math.Random _random = math.Random();

  // Controladores de animação
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Probabilidades base para cada rank (totalizando 100%)
  final Map<String, double> _rankProbabilities = {
    'E': 35.0,
    'D': 25.0,
    'C': 15.0,
    'B': 10.0,
    'A': 7.0,
    'S': 4.0,
    'SS': 2.5,
    'SSS': 1.0,
    'Global': 0.5,
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserCoins();
    _selectedItemType = 'Cabeça';
    _initializeItemsIfNeeded();
    _setupCoinsListener();
  }

  void _initializeAnimations() {
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _glowController.repeat(reverse: true);
  }

  void _setupCoinsListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && mounted) {
          setState(() {
            _userCoins = snapshot.data()?['levelingCoins'] ?? 0;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadUserCoins() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('Usuário não autenticado. Faça login novamente.');
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        if(mounted){
          setState(() {
            _userCoins = userDoc.data()?['levelingCoins'] ?? 0;
          });
        }
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'levelingCoins': 10,
          'createdAt': FieldValue.serverTimestamp(),
        });
        if(mounted){
          setState(() {
            _userCoins = 10;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao carregar informações do usuário.');
    }
  }

  String _selectRandomRank() {
    double randomValue = _random.nextDouble() * 100;
    double cumulativeProbability = 0;

    for (var entry in _rankProbabilities.entries) {
      cumulativeProbability += entry.value;
      if (randomValue <= cumulativeProbability) {
        return entry.key;
      }
    }
    
    return 'E';
  }

  Future<void> _spinRoulette() async {
    if (_isSpinning || _userCoins < 1) return;

    setState(() {
      _isSpinning = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('Usuário não autenticado. Faça login novamente.');
        setState(() => _isSpinning = false);
        return;
      }

      final userDocSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDocSnapshot.exists) {
        _showErrorSnackBar('Dados do usuário não encontrados.');
        setState(() => _isSpinning = false);
        if (_cardKey.currentState?.isFront == false) {
            _cardKey.currentState?.toggleCard();
        }
        return;
      }

      final currentCoins = userDocSnapshot.data()?['levelingCoins'] ?? 0;
      if (currentCoins < 1) {
        _showErrorSnackBar('Moedas insuficientes.');
        setState(() => _isSpinning = false);
        return;
      }

      _cardKey.currentState?.toggleCard();
      await Future.delayed(const Duration(seconds: 2));

      QuerySnapshot itemsSnapshot;
      try {
        itemsSnapshot = await FirebaseFirestore.instance
            .collection('items')
            .where('type', isEqualTo: _selectedItemType)
            .where('rank', isEqualTo: _selectRandomRank())
            .get();
        
      } catch (e) {
        _showErrorSnackBar('Erro ao buscar itens no banco de dados.');
        setState(() => _isSpinning = false);
        if (_cardKey.currentState?.isFront == false) {
            _cardKey.currentState?.toggleCard();
        }
        return;
      }

      if (itemsSnapshot.docs.isEmpty) {
        final rankOrder = ['E', 'D', 'C', 'B', 'A', 'S', 'SS', 'SSS', 'Global'];
        bool foundItems = false;
        
        for (String fallbackRank in rankOrder) {
          try {
            itemsSnapshot = await FirebaseFirestore.instance
                .collection('items')
                .where('type', isEqualTo: _selectedItemType)
                .where('rank', isEqualTo: fallbackRank)
                .get();
            
            if (itemsSnapshot.docs.isNotEmpty) {
              foundItems = true;
              break;
            }
          } catch (e) {
            print('Error fetching fallback items for rank $fallbackRank: $e');
            continue;
          }
        }
        
        if (!foundItems) {
          try {
            itemsSnapshot = await FirebaseFirestore.instance
                .collection('items')
                .where('type', isEqualTo: _selectedItemType)
                .get();
            
            if (itemsSnapshot.docs.isEmpty) {
              _showErrorSnackBar('Nenhum item encontrado para o tipo $_selectedItemType.');
              setState(() => _isSpinning = false);
                if (_cardKey.currentState?.isFront == false) {
                  _cardKey.currentState?.toggleCard();
                }
              return;
            }
          } catch (e) {
            _showErrorSnackBar('Erro crítico ao buscar itens.');
            setState(() => _isSpinning = false);
              if (_cardKey.currentState?.isFront == false) {
                  _cardKey.currentState?.toggleCard();
              }
            return;
          }
        }
      }

      final inventorySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .get();

      final List<String> ownedItemIds = inventorySnapshot.docs
          .map((doc) {
            final data = doc.data(); 
            return data['id'];
          })
          .whereType<String>()
          .toList();

      final availableItems = itemsSnapshot.docs
          .where((doc) => !ownedItemIds.contains(doc.id))
          .toList();

      if (availableItems.isEmpty) {
        _showErrorSnackBar('Você já possui todos os itens disponíveis deste tipo e rank!');
        setState(() {
          _isSpinning = false;
        });
        if (_cardKey.currentState?.isFront == false) {
          _cardKey.currentState?.toggleCard();
        }
        return;
      }

      final randomItem = availableItems[_random.nextInt(availableItems.length)];
      final itemData = randomItem.data() as Map<String, dynamic>;

      final itemName = itemData['name'] as String? ?? 'Item Desconhecido';
      final itemType = itemData['type'] as String? ?? 'Desconhecido';
      final itemRank = itemData['rank'] as String? ?? 'E';
      


      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          throw Exception('Usuário não encontrado');
        }

        final currentCoins = userDoc.data()?['levelingCoins'] ?? 0;
        if (currentCoins < 1) {
          throw Exception('Moedas insuficientes');
        }

        transaction.update(userRef, {
          'levelingCoins': FieldValue.increment(-1)
        });

        final inventoryRef = userRef.collection('inventory').doc();
        transaction.set(inventoryRef, {
          'id': randomItem.id,
          'name': itemName,
          'type': itemType,
          'rank': itemRank,
          'acquiredAt': FieldValue.serverTimestamp(),
          'isNew': true,
          'statBonuses': itemData['statBonuses'] ?? {},
          'iconCodePoint': _getIconForSlotType(itemType).codePoint,
          'iconFontFamily': _getIconForSlotType(itemType).fontFamily,
        });
      });

      if(mounted){
        setState(() {
          _userCoins--;
        });
      }

      if (mounted) {
        _showStyledDialog(
          context: context,
          titleText: "Item Ganho!",
          icon: Icons.card_giftcard_rounded,
          iconColor: itemRankColors[itemRank] ?? accentColorBlue,
          contentWidgets: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          (itemRankColors[itemRank] ?? accentColorBlue).withOpacity(0.3),
                          (itemRankColors[itemRank] ?? accentColorBlue).withOpacity(0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: itemRankColors[itemRank] ?? accentColorBlue,
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getIconForSlotType(itemType),
                      size: 48,
                      color: itemRankColors[itemRank] ?? accentColorBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    itemName,
                    style: TextStyle(
                      color: itemRankColors[itemRank] ?? textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (itemRankColors[itemRank] ?? accentColorBlue).withOpacity(0.3),
                          (itemRankColors[itemRank] ?? accentColorBlue).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: itemRankColors[itemRank] ?? accentColorBlue,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      "Rank: $itemRank",
                      style: TextStyle(
                        color: itemRankColors[itemRank] ?? textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          actions: [
            _buildDialogButton(
              context,
              "INCRÍVEL!",
              () => Navigator.of(context).pop(),
              true,
            ),
          ],
        );
      }

    } catch (e) {
      String errorMessage = 'Erro desconhecido'; 
      
      if (e.toString().toLowerCase().contains('permission-denied')) {
        errorMessage = 'Permissões insuficientes.';
      } else if (e.toString().toLowerCase().contains('not-found')) {
        errorMessage = 'Dados não encontrados.';
      } else if (e.toString().contains('Moedas insuficientes')) {
        errorMessage = 'Você não tem moedas suficientes.';
      } else {
        errorMessage = 'Erro ao processar solicitação.';
      }
      
      _showErrorSnackBar(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isSpinning = false;
        });
        
        if (_cardKey.currentState != null && _cardKey.currentState!.isFront == false) {
          _cardKey.currentState!.toggleCard();
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      _showStyledDialog(
        context: context,
        titleText: "Erro",
        icon: Icons.error_outline,
        iconColor: Colors.red,
        contentWidgets: [
          Text(message, style: const TextStyle(color: textColor)),
        ],
        actions: [
          _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
        ],
      );
    }
  }

  Future<void> _initializeItemsIfNeeded() async {
    try {
      final itemsSnapshot = await FirebaseFirestore.instance
          .collection('items')
          .limit(1)
          .get();

      if (itemsSnapshot.docs.isEmpty) {
        await _initializeItems();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao verificar/inicializar itens: ${e.toString()}');
      }
    }
  }

  Future<void> _initializeItems() async {
    try {
      final items = [
        // Itens de Cabeça
        {'id': 'head_e', 'name': 'Chapéu de Aprendiz', 'type': 'Cabeça', 'rank': 'E', 'statBonuses': {'VIT': 1}},
        {'id': 'head_d', 'name': 'Capacete de Ferro', 'type': 'Cabeça', 'rank': 'D', 'statBonuses': {'VIT': 2}},
        {'id': 'head_c', 'name': 'Coroa de Prata', 'type': 'Cabeça', 'rank': 'C', 'statBonuses': {'VIT': 3, 'INT': 1}},
        {'id': 'head_b', 'name': 'Elmo de Aço', 'type': 'Cabeça', 'rank': 'B', 'statBonuses': {'VIT': 4, 'FOR': 1}},
        {'id': 'head_a', 'name': 'Tiara Mágica', 'type': 'Cabeça', 'rank': 'A', 'statBonuses': {'INT': 5, 'MP_MAX_BONUS': 20}},
        {'id': 'head_s', 'name': 'Coroa Real', 'type': 'Cabeça', 'rank': 'S', 'statBonuses': {'VIT': 6, 'INT': 3, 'MP_MAX_BONUS': 30}},
        {'id': 'head_ss', 'name': 'Diadema Ancestral', 'type': 'Cabeça', 'rank': 'SS', 'statBonuses': {'VIT': 8, 'INT': 5, 'MP_MAX_BONUS': 50}},
        {'id': 'head_sss', 'name': 'Coroa Celestial', 'type': 'Cabeça', 'rank': 'SSS', 'statBonuses': {'VIT': 10, 'INT': 8, 'MP_MAX_BONUS': 100}},
        {'id': 'head_global', 'name': 'Coroa do Destino', 'type': 'Cabeça', 'rank': 'Global', 'statBonuses': {'VIT': 15, 'INT': 15, 'MP_MAX_BONUS': 200}},
        
        // Itens de Peitoral
        {'id': 'chest_e', 'name': 'Túnica de Aprendiz', 'type': 'Peitoral', 'rank': 'E', 'statBonuses': {'VIT': 1}},
        {'id': 'chest_d', 'name': 'Armadura de Couro', 'type': 'Peitoral', 'rank': 'D', 'statBonuses': {'VIT': 2}},
        {'id': 'chest_c', 'name': 'Peitoral de Bronze', 'type': 'Peitoral', 'rank': 'C', 'statBonuses': {'VIT': 3, 'FOR': 1}},
        {'id': 'chest_b', 'name': 'Armadura de Aço', 'type': 'Peitoral', 'rank': 'B', 'statBonuses': {'VIT': 4, 'FOR': 2}},
        {'id': 'chest_a', 'name': 'Túnica Arcana', 'type': 'Peitoral', 'rank': 'A', 'statBonuses': {'INT': 5, 'MP_MAX_BONUS': 20}},
        {'id': 'chest_s', 'name': 'Armadura Real', 'type': 'Peitoral', 'rank': 'S', 'statBonuses': {'VIT': 6, 'FOR': 3, 'HP_MAX_BONUS': 30}},
        {'id': 'chest_ss', 'name': 'Peitoral Ancestral', 'type': 'Peitoral', 'rank': 'SS', 'statBonuses': {'VIT': 8, 'FOR': 5, 'HP_MAX_BONUS': 50}},
        {'id': 'chest_sss', 'name': 'Armadura Celestial', 'type': 'Peitoral', 'rank': 'SSS', 'statBonuses': {'VIT': 10, 'FOR': 8, 'HP_MAX_BONUS': 100}},
        {'id': 'chest_global', 'name': 'Armadura do Destino', 'type': 'Peitoral', 'rank': 'Global', 'statBonuses': {'VIT': 15, 'FOR': 15, 'HP_MAX_BONUS': 200}},
        
        // Itens de Pernas
        {'id': 'legs_e', 'name': 'Calças de Aprendiz', 'type': 'Pernas', 'rank': 'E', 'statBonuses': {'AGI': 1}},
        {'id': 'legs_d', 'name': 'Calças de Couro', 'type': 'Pernas', 'rank': 'D', 'statBonuses': {'AGI': 2}},
        {'id': 'legs_c', 'name': 'Grevas de Bronze', 'type': 'Pernas', 'rank': 'C', 'statBonuses': {'AGI': 3, 'VIT': 1}},
        {'id': 'legs_b', 'name': 'Calças de Aço', 'type': 'Pernas', 'rank': 'B', 'statBonuses': {'AGI': 4, 'VIT': 2}},
        {'id': 'legs_a', 'name': 'Calças Arcanas', 'type': 'Pernas', 'rank': 'A', 'statBonuses': {'AGI': 5, 'INT': 2}},
        {'id': 'legs_s', 'name': 'Calças Reais', 'type': 'Pernas', 'rank': 'S', 'statBonuses': {'AGI': 6, 'VIT': 3}},
        {'id': 'legs_ss', 'name': 'Grevas Ancestrais', 'type': 'Pernas', 'rank': 'SS', 'statBonuses': {'AGI': 8, 'VIT': 5}},
        {'id': 'legs_sss', 'name': 'Calças Celestiais', 'type': 'Pernas', 'rank': 'SSS', 'statBonuses': {'AGI': 10, 'VIT': 8}},
        {'id': 'legs_global', 'name': 'Calças do Destino', 'type': 'Pernas', 'rank': 'Global', 'statBonuses': {'AGI': 15, 'VIT': 15}},
        
        // Pés
        {'id': 'feet_e', 'name': 'Sandálias de Aprendiz', 'type': 'Pés', 'rank': 'E', 'statBonuses': {'AGI': 1}},
        {'id': 'feet_d', 'name': 'Botas de Couro', 'type': 'Pés', 'rank': 'D', 'statBonuses': {'AGI': 2}},
        {'id': 'feet_c', 'name': 'Sapatos de Bronze', 'type': 'Pés', 'rank': 'C', 'statBonuses': {'AGI': 3, 'PER': 1}},
        {'id': 'feet_b', 'name': 'Botas de Aço', 'type': 'Pés', 'rank': 'B', 'statBonuses': {'AGI': 4, 'PER': 2}},
        {'id': 'feet_a', 'name': 'Botas Arcanas', 'type': 'Pés', 'rank': 'A', 'statBonuses': {'AGI': 5, 'INT': 2}},
        {'id': 'feet_s', 'name': 'Botas Reais', 'type': 'Pés', 'rank': 'S', 'statBonuses': {'AGI': 6, 'PER': 3}},
        {'id': 'feet_ss', 'name': 'Botas Ancestrais', 'type': 'Pés', 'rank': 'SS', 'statBonuses': {'AGI': 8, 'PER': 5}},
        {'id': 'feet_sss', 'name': 'Botas Celestiais', 'type': 'Pés', 'rank': 'SSS', 'statBonuses': {'AGI': 10, 'PER': 8}},
        {'id': 'feet_global', 'name': 'Botas do Destino', 'type': 'Pés', 'rank': 'Global', 'statBonuses': {'AGI': 15, 'PER': 15}},
        
        // Mão Direita
        {'id': 'right_hand_e', 'name': 'Luva Simples', 'type': 'Mão Direita', 'rank': 'E', 'statBonuses': {'FOR': 1}},
        {'id': 'right_hand_d', 'name': 'Luva de Couro', 'type': 'Mão Direita', 'rank': 'D', 'statBonuses': {'FOR': 2}},
        {'id': 'right_hand_c', 'name': 'Luva de Bronze', 'type': 'Mão Direita', 'rank': 'C', 'statBonuses': {'FOR': 3, 'AGI': 1}},
        {'id': 'right_hand_b', 'name': 'Luva de Aço', 'type': 'Mão Direita', 'rank': 'B', 'statBonuses': {'FOR': 4, 'AGI': 2}},
        {'id': 'right_hand_a', 'name': 'Luva Arcana', 'type': 'Mão Direita', 'rank': 'A', 'statBonuses': {'FOR': 5, 'INT': 2}},
        {'id': 'right_hand_s', 'name': 'Luva Real', 'type': 'Mão Direita', 'rank': 'S', 'statBonuses': {'FOR': 6, 'AGI': 3}},
        {'id': 'right_hand_ss', 'name': 'Luva Ancestral', 'type': 'Mão Direita', 'rank': 'SS', 'statBonuses': {'FOR': 8, 'AGI': 5}},
        {'id': 'right_hand_sss', 'name': 'Luva Celestial', 'type': 'Mão Direita', 'rank': 'SSS', 'statBonuses': {'FOR': 10, 'AGI': 8}},
        {'id': 'right_hand_global', 'name': 'Luva do Destino', 'type': 'Mão Direita', 'rank': 'Global', 'statBonuses': {'FOR': 15, 'AGI': 15}},
        
        // Mão Esquerda
        {'id': 'left_hand_e', 'name': 'Escudo Simples', 'type': 'Mão Esquerda', 'rank': 'E', 'statBonuses': {'VIT': 1}},
        {'id': 'left_hand_d', 'name': 'Escudo de Couro', 'type': 'Mão Esquerda', 'rank': 'D', 'statBonuses': {'VIT': 2}},
        {'id': 'left_hand_c', 'name': 'Escudo de Bronze', 'type': 'Mão Esquerda', 'rank': 'C', 'statBonuses': {'VIT': 3, 'FOR': 1}},
        {'id': 'left_hand_b', 'name': 'Escudo de Aço', 'type': 'Mão Esquerda', 'rank': 'B', 'statBonuses': {'VIT': 4, 'FOR': 2}},
        {'id': 'left_hand_a', 'name': 'Escudo Arcano', 'type': 'Mão Esquerda', 'rank': 'A', 'statBonuses': {'VIT': 5, 'INT': 2}},
        {'id': 'left_hand_s', 'name': 'Escudo Real', 'type': 'Mão Esquerda', 'rank': 'S', 'statBonuses': {'VIT': 6, 'FOR': 3}},
        {'id': 'left_hand_ss', 'name': 'Escudo Ancestral', 'type': 'Mão Esquerda', 'rank': 'SS', 'statBonuses': {'VIT': 8, 'FOR': 5}},
        {'id': 'left_hand_sss', 'name': 'Escudo Celestial', 'type': 'Mão Esquerda', 'rank': 'SSS', 'statBonuses': {'VIT': 10, 'FOR': 8}},
        {'id': 'left_hand_global', 'name': 'Escudo do Destino', 'type': 'Mão Esquerda', 'rank': 'Global', 'statBonuses': {'VIT': 15, 'FOR': 15}},
        
        // Orelhas
        {'id': 'ear_e', 'name': 'Brinco Simples', 'type': 'Orelhas', 'rank': 'E', 'statBonuses': {'PER': 1}},
        {'id': 'ear_d', 'name': 'Brinco de Prata', 'type': 'Orelhas', 'rank': 'D', 'statBonuses': {'PER': 2}},
        {'id': 'ear_c', 'name': 'Brinco de Ouro', 'type': 'Orelhas', 'rank': 'C', 'statBonuses': {'PER': 3, 'INT': 1}},
        {'id': 'ear_b', 'name': 'Brinco de Safira', 'type': 'Orelhas', 'rank': 'B', 'statBonuses': {'PER': 4, 'INT': 2}},
        {'id': 'ear_a', 'name': 'Earcuff Dracônico', 'type': 'Orelhas', 'rank': 'A', 'statBonuses': {'PER': 5, 'INT': 3}},
        {'id': 'ear_s', 'name': 'Brinco da Sussurrante', 'type': 'Orelhas', 'rank': 'S', 'statBonuses': {'PER': 6, 'INT': 4}},
        {'id': 'ear_ss', 'name': 'Orbe Auditivo Ancestral', 'type': 'Orelhas', 'rank': 'SS', 'statBonuses': {'PER': 8, 'INT': 6}},
        {'id': 'ear_sss', 'name': 'Gema da Audição Celestial', 'type': 'Orelhas', 'rank': 'SSS', 'statBonuses': {'PER': 10, 'INT': 8}},
        {'id': 'ear_global', 'name': 'Brinco do Eco Universal', 'type': 'Orelhas', 'rank': 'Global', 'statBonuses': {'PER': 15, 'INT': 15}},
        
        // Colar
        {'id': 'neck_e', 'name': 'Colar de Contas', 'type': 'Colar', 'rank': 'E', 'statBonuses': {'INT': 1}},
        {'id': 'neck_d', 'name': 'Amuleto de Proteção', 'type': 'Colar', 'rank': 'D', 'statBonuses': {'INT': 2}},
        {'id': 'neck_c', 'name': 'Pingente de Jade', 'type': 'Colar', 'rank': 'C', 'statBonuses': {'INT': 3, 'VIT': 1}},
        {'id': 'neck_b', 'name': 'Corrente de Mithril', 'type': 'Colar', 'rank': 'B', 'statBonuses': {'INT': 4, 'VIT': 2}},
        {'id': 'neck_a', 'name': 'Talismã do Mago', 'type': 'Colar', 'rank': 'A', 'statBonuses': {'INT': 5, 'MP_MAX_BONUS': 20}},
        {'id': 'neck_s', 'name': 'Gargantilha da Realeza', 'type': 'Colar', 'rank': 'S', 'statBonuses': {'INT': 6, 'MP_MAX_BONUS': 30}},
        {'id': 'neck_ss', 'name': 'Coração de Titã', 'type': 'Colar', 'rank': 'SS', 'statBonuses': {'INT': 8, 'MP_MAX_BONUS': 50}},
        {'id': 'neck_sss', 'name': 'Lágrima de Estrela', 'type': 'Colar', 'rank': 'SSS', 'statBonuses': {'INT': 10, 'MP_MAX_BONUS': 100}},
        {'id': 'neck_global', 'name': 'Medalhão do Cosmos', 'type': 'Colar', 'rank': 'Global', 'statBonuses': {'INT': 15, 'MP_MAX_BONUS': 200}},
        
        // Rosto
        {'id': 'face_e', 'name': 'Tapa-olho de Couro', 'type': 'Rosto', 'rank': 'E', 'statBonuses': {'PER': 1}},
        {'id': 'face_d', 'name': 'Máscara Simples', 'type': 'Rosto', 'rank': 'D', 'statBonuses': {'PER': 2}},
        {'id': 'face_c', 'name': 'Visor de Cristal', 'type': 'Rosto', 'rank': 'C', 'statBonuses': {'PER': 3, 'INT': 1}},
        {'id': 'face_b', 'name': 'Máscara de Aço', 'type': 'Rosto', 'rank': 'B', 'statBonuses': {'PER': 4, 'INT': 2}},
        {'id': 'face_a', 'name': 'Véu Ilusório', 'type': 'Rosto', 'rank': 'A', 'statBonuses': {'PER': 5, 'INT': 2}},
        {'id': 'face_s', 'name': 'Máscara do Espectro', 'type': 'Rosto', 'rank': 'S', 'statBonuses': {'PER': 6, 'INT': 3}},
        {'id': 'face_ss', 'name': 'Elmo Facial Ancestral', 'type': 'Rosto', 'rank': 'SS', 'statBonuses': {'PER': 8, 'INT': 5}},
        {'id': 'face_sss', 'name': 'Face da Divindade', 'type': 'Rosto', 'rank': 'SSS', 'statBonuses': {'PER': 10, 'INT': 8}},
        {'id': 'face_global', 'name': 'Semblante do Vazio', 'type': 'Rosto', 'rank': 'Global', 'statBonuses': {'PER': 15, 'INT': 15}},

        // Itens de Bracelete
        {'id': 'wrist_e', 'name': 'Pulseira de Corda', 'type': 'Bracelete', 'rank': 'E', 'statBonuses': {'AGI': 1}},
        {'id': 'wrist_d', 'name': 'Bracelete de Ferro', 'type': 'Bracelete', 'rank': 'D', 'statBonuses': {'AGI': 2}},
        {'id': 'wrist_c', 'name': 'Munhequeira Rúnica', 'type': 'Bracelete', 'rank': 'C', 'statBonuses': {'AGI': 3, 'FOR': 1}},
        {'id': 'wrist_b', 'name': 'Bracelete de Escamas', 'type': 'Bracelete', 'rank': 'B', 'statBonuses': {'AGI': 4, 'FOR': 2}},
        {'id': 'wrist_a', 'name': 'Vínculo de Energia', 'type': 'Bracelete', 'rank': 'A', 'statBonuses': {'AGI': 5, 'INT': 2}},
        {'id': 'wrist_s', 'name': 'Manopla do Guardião', 'type': 'Bracelete', 'rank': 'S', 'statBonuses': {'FOR': 6, 'VIT': 3}},
        {'id': 'wrist_ss', 'name': 'Bracelete do Tempo', 'type': 'Bracelete', 'rank': 'SS', 'statBonuses': {'AGI': 8, 'PER': 5}},
        {'id': 'wrist_sss', 'name': 'Grilhão Etéreo', 'type': 'Bracelete', 'rank': 'SSS', 'statBonuses': {'FOR': 10, 'AGI': 8}},
        {'id': 'wrist_global', 'name': 'Aro do Infinito', 'type': 'Bracelete', 'rank': 'Global', 'statBonuses': {'FOR': 15, 'AGI': 15}},
        
        // Itens de Acessório Esquerdo (Anéis)
        {'id': 'acc_left_e', 'name': 'Anel de Estanho', 'type': 'Acessório E.', 'rank': 'E', 'statBonuses': {'FOR': 1}},
        {'id': 'acc_left_d', 'name': 'Anel de Prata com Selo', 'type': 'Acessório E.', 'rank': 'D', 'statBonuses': {'FOR': 1, 'INT': 1}},
        {'id': 'acc_left_c', 'name': 'Anel de Topázio', 'type': 'Acessório E.', 'rank': 'C', 'statBonuses': {'INT': 2, 'PER': 1}},
        {'id': 'acc_left_b', 'name': 'Anel da Guilda', 'type': 'Acessório E.', 'rank': 'B', 'statBonuses': {'FOR': 2, 'VIT': 2}},
        {'id': 'acc_left_a', 'name': 'Anel de Vitalidade', 'type': 'Acessório E.', 'rank': 'A', 'statBonuses': {'VIT': 4, 'HP_MAX_BONUS': 15}},
        {'id': 'acc_left_s', 'name': 'Anel do Lorde', 'type': 'Acessório E.', 'rank': 'S', 'statBonuses': {'FOR': 3, 'VIT': 3, 'INT': 2}},
        {'id': 'acc_left_ss', 'name': 'Anel do Lich', 'type': 'Acessório E.', 'rank': 'SS', 'statBonuses': {'INT': 6, 'MP_MAX_BONUS': 40}},
        {'id': 'acc_left_sss', 'name': 'Aliança dos Querubins', 'type': 'Acessório E.', 'rank': 'SSS', 'statBonuses': {'FOR': 4, 'VIT': 4, 'AGI': 4, 'INT': 4, 'PER': 4}},
        {'id': 'acc_left_global', 'name': 'Anel da Singularidade', 'type': 'Acessório E.', 'rank': 'Global', 'statBonuses': {'FOR': 8, 'VIT': 8, 'AGI': 8, 'INT': 8, 'PER': 8}},

        // Itens de Acessório Direito (Anéis)
        {'id': 'acc_right_e', 'name': 'Anel de Osso', 'type': 'Acessório D.', 'rank': 'E', 'statBonuses': {'VIT': 1}},
        {'id': 'acc_right_d', 'name': 'Anel de Cobre com Selo', 'type': 'Acessório D.', 'rank': 'D', 'statBonuses': {'VIT': 1, 'PER': 1}},
        {'id': 'acc_right_c', 'name': 'Anel de Rubi', 'type': 'Acessório D.', 'rank': 'C', 'statBonuses': {'FOR': 2, 'AGI': 1}},
        {'id': 'acc_right_b', 'name': 'Anel do Clã', 'type': 'Acessório D.', 'rank': 'B', 'statBonuses': {'AGI': 2, 'PER': 2}},
        {'id': 'acc_right_a', 'name': 'Anel de Poder', 'type': 'Acessório D.', 'rank': 'A', 'statBonuses': {'FOR': 4, 'MP_MAX_BONUS': 15}},
        {'id': 'acc_right_s', 'name': 'Anel da Soberania', 'type': 'Acessório D.', 'rank': 'S', 'statBonuses': {'AGI': 3, 'PER': 3, 'INT': 2}},
        {'id': 'acc_right_ss', 'name': 'Anel do Arcanjo', 'type': 'Acessório D.', 'rank': 'SS', 'statBonuses': {'PER': 6, 'HP_MAX_BONUS': 40}},
        {'id': 'acc_right_sss', 'name': 'Selo de Salomão', 'type': 'Acessório D.', 'rank': 'SSS', 'statBonuses': {'FOR': 4, 'VIT': 4, 'AGI': 4, 'INT': 4, 'PER': 4}},
        {'id': 'acc_right_global', 'name': 'Anel da Onipresença', 'type': 'Acessório D.', 'rank': 'Global', 'statBonuses': {'FOR': 8, 'VIT': 8, 'AGI': 8, 'INT': 8, 'PER': 8}},
      ];

      final addBatch = FirebaseFirestore.instance.batch();
      
      for (var item in items) {
        final docId = item['id'] as String; 
        final docRef = FirebaseFirestore.instance.collection('items').doc(docId);
        // Usar SetOptions(merge: false) para sobrescrever completamente
        addBatch.set(docRef, {
          ...item,
          'acquiredAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: false));
      }

      await addBatch.commit();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erro ao inicializar itens: ${e.toString()}');
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor,
              primaryColor.withOpacity(0.8),
              accentColorPurple.withOpacity(0.1),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200, // Aumentar altura para caber tudo
              floating: false,
              pinned: true,
              backgroundColor: primaryColor.withOpacity(0.5),
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColorBlue.withOpacity(0.2),
                        accentColorPurple.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: kToolbarHeight - 20), // Espaço para não sobrepor a status bar
                        // Título Estilizado
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D1E33).withOpacity(0.7),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: accentColorBlue.withOpacity(0.5)),
                             boxShadow: [
                                BoxShadow(
                                  color: accentColorBlue.withOpacity(0.5),
                                  blurRadius: 8.0,
                                  spreadRadius: 2.0,
                                ),
                              ],
                          ),
                          child: const Text(
                            'Roleta de Itens',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: accentColorBlue,
                                ),
                                Shadow(
                                  blurRadius: 20.0,
                                  color: accentColorBlue,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Contador de Moedas Animado
                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColorBlue.withOpacity(_glowAnimation.value * 0.5),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                                gradient: LinearGradient(
                                  colors: [
                                    accentColorBlue.withOpacity(0.3),
                                    accentColorPurple.withOpacity(0.3),
                                  ],
                                ),
                                border: Border.all(
                                  color: accentColorBlue.withOpacity(_glowAnimation.value),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.monetization_on,
                                    color: Colors.amber,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$_userCoins Leveling Coins',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: accentColorBlue),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildTypeButton('Cabeça', Icons.account_circle_outlined),
                        _buildTypeButton('Peitoral', Icons.shield_outlined),
                        _buildTypeButton('Pernas', Icons.accessibility_new_outlined),
                        _buildTypeButton('Pés', Icons.directions_walk),
                        _buildTypeButton('Mão Direita', Icons.pan_tool_alt_outlined),
                        _buildTypeButton('Mão Esquerda', Icons.pan_tool_alt_outlined),
                        _buildTypeButton('Orelhas', Icons.headset_outlined),
                        _buildTypeButton('Colar', Icons.bookmark_outlined),
                        _buildTypeButton('Rosto', Icons.face_outlined),
                        _buildTypeButton('Bracelete', Icons.watch_outlined),
                        _buildTypeButton('Acessório E.', Icons.fingerprint),
                        _buildTypeButton('Acessório D.', Icons.fingerprint),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      alignment: WrapAlignment.center,
                      children: _rankProbabilities.entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: itemRankColors[entry.key]?.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: itemRankColors[entry.key] ?? Colors.grey,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${entry.key}: ${entry.value}%',
                            style: TextStyle(
                              color: itemRankColors[entry.key] ?? Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12, // Um pouco menor para caber melhor
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: FlipCard(
                        key: _cardKey,
                        flipOnTouch: false,
                        front: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            color: panelBgColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: accentColorBlue.withOpacity(0.3)),
                          ),
                          child: const Center(
                            child: Text(
                              'Gire a Roleta!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        back: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            color: panelBgColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: accentColorBlue.withOpacity(0.3)),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(accentColorBlue),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Girando...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _userCoins >= 1 && !_isSpinning ? _spinRoulette : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                        backgroundColor: accentColorPurple,
                        foregroundColor: textColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(color: accentColorBlue.withOpacity(0.7)),
                        ),
                        disabledBackgroundColor: Colors.grey.shade700,
                      ),
                      child: Text(
                        _isSpinning ? 'Girando...' : 'Girar Roleta (1 Coin)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(String type, IconData icon) {
    final isSelected = _selectedItemType == type;
    return InkWell(
      onTap: () {
        if (!_isSpinning) {
          setState(() {
            _selectedItemType = type;
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColorBlue.withOpacity(0.8)
              : panelBgColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? accentColorBlue
                : accentColorBlue.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColorBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? textColor
                  : accentColorBlue.withOpacity(0.7),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              type,
              style: TextStyle(
                color: isSelected
                    ? textColor
                    : textColor.withOpacity(0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
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
                  style: const TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18
                  ),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(children: contentWidgets),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          actions: [
            Row(
              mainAxisAlignment: actions.length > 1 ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.center,
              children: actions.length > 1
                  ? List.generate(actions.length * 2 - 1, (index) {
                      if (index.isEven) return Expanded(child: actions[index ~/ 2]);
                      return const SizedBox(width: 10);
                    })
                  : (actions.isNotEmpty ? [Expanded(child: actions.first)] : []),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogButton(BuildContext context, String text, VoidCallback onPressed, bool isPrimary) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? accentColorPurple : Colors.grey.shade700,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(
            color: isPrimary ? accentColorBlue.withOpacity(0.7) : Colors.transparent,
            width: 1.5
          ),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.bold)
      ),
      child: Text(text.toUpperCase()),
    );
  }

  IconData _getIconForSlotType(String type) {
    switch (type) {
      case 'Cabeça':
        return Icons.account_circle;
      case 'Peitoral':
        return Icons.shield;
      case 'Pernas':
        return Icons.accessibility_new;
      case 'Pés':
        return Icons.directions_walk;
      case 'Mão Direita':
      case 'Mão Esquerda':
        return Icons.pan_tool_alt;
      case 'Orelhas':
        return Icons.headset_outlined;
      case 'Colar':
        return Icons.bookmark_outlined;
      case 'Rosto':
        return Icons.face_outlined;
      case 'Bracelete':
        return Icons.watch_outlined;
      case 'Acessório E.':
      case 'Acessório D.':
        return Icons.fingerprint;
      default:
        return Icons.help_outline;
    }
  }
}