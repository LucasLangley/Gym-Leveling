// Em lib/screens/profile_screen.dart
// ignore_for_file: avoid_print, deprecated_member_use, unnecessary_brace_in_string_interps, prefer_const_constructors, use_build_context_synchronously, avoid_types_as_parameter_names

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; // Para a função pow na progressão de EXP
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/aura_calculator.dart' as aura_utils;
import 'treino_screen.dart';

// --- CORES ---
const Color primaryColor = Color(0xFF0A0E21);
const Color accentColorBlue = Color(0xFF40C4FF);
const Color accentColorPurple = Color(0xFF8A2BE2);
const Color textColor = Colors.white;
const Color panelBgColor = Color(0x991D1E33);
const Color greenStatColor = Colors.greenAccent;
const Color yellowWarningColor = Colors.yellowAccent;
const Color levelUpColor = Colors.amberAccent; // Cor para notificações de Level Up
const Color prColor = Colors.amber; // Adicione esta linha para definir a nova cor

// --- CORES PARA RANKS DE ITENS ---
const Map<String, Color> itemRankColors = {
  'E': Colors.grey,
  'D': Colors.green,
  'C': Colors.yellowAccent,
  'B': Color(0xFFADADAD),
  'A': Colors.orange,
  'S': Colors.redAccent,
  'SS': Colors.pinkAccent,
  'SSS': Color(0xFF6F7FFF),
  'Global': accentColorPurple,
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

// --- Modelo de Item ---
class Item {
  final String id;
  final String name;
  final String slotType;
  final String rank;
  final DateTime dateAcquired;
  final IconData icon;
  bool isNew;
  final Map<String, int> statBonuses;

  Item({
    required this.id,
    required this.name,
    required this.slotType,
    required this.rank,
    required this.dateAcquired,
    required this.icon,
    this.isNew = false,
    this.statBonuses = const {},
  });
}

// --- Widget para Slot de Equipamento ---
class EquipmentSlotWidget extends StatelessWidget {
  final String slotName;
  final IconData placeholderIcon;
  final bool hasNewItem;
  final bool isEquipped;
  final VoidCallback? onTap;
  final Map<String, dynamic>? equippedItem;

  const EquipmentSlotWidget({
    required this.slotName,
    required this.placeholderIcon,
    this.hasNewItem = false,
    this.isEquipped = false,
    this.onTap,
    this.equippedItem,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 3.0),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: panelBgColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isEquipped ? accentColorPurple.withOpacity(0.6) : accentColorBlue.withOpacity(0.3),
            width: isEquipped ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              equippedItem != null ? _getIconForRank(equippedItem!['rank']) : placeholderIcon,
              color: equippedItem != null ? _getColorForRank(equippedItem!['rank']) : accentColorBlue.withOpacity(0.7),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    equippedItem != null ? equippedItem!['name'] : slotName,
                    style: TextStyle(
                      color: equippedItem != null ? textColor : textColor.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: equippedItem != null ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (equippedItem != null && equippedItem!['rank'] != null)
                    Text(
                      'Rank ${equippedItem!['rank']}',
                      style: TextStyle(
                        color: _getColorForRank(equippedItem!['rank']),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForRank(String rank) {
    switch (rank) {
      case 'SSS':
        return Icons.star;
      case 'SS':
        return Icons.star;
      case 'S':
        return Icons.star;
      case 'A':
        return Icons.star_half;
      case 'B':
        return Icons.star_border;
      case 'C':
        return Icons.star_border;
      case 'D':
        return Icons.star_border;
      case 'E':
        return Icons.star_border;
      default:
        return placeholderIcon;
    }
  }

  Color _getColorForRank(String rank) {
    return itemRankColors[rank] ?? accentColorBlue;
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

// --- FUNÇÕES AUXILIARES PARA TÍTULOS E CLASSES ---
bool _checkTitleCondition(String condition, Map<String, int> stats, int level) {
  if (condition == 'default') return true;
  
  final parts = condition.split(' ');
  if (parts.length != 3) return false;
  
  final stat = parts[0];
  final operator = parts[1];
  final valueStr = parts[2];
  
  final value = int.tryParse(valueStr);
  if (value == null) return false;
  
  if (stat == 'level') {
    if (operator == '>=') return level >= value;
    if (operator == '<=') return level <= value;
    if (operator == '==') return level == value;
  } else {
    final currentValue = stats[stat] ?? 0;
    if (operator == '>=') return currentValue >= value;
    if (operator == '<=') return currentValue <= value;
    if (operator == '==') return currentValue == value;
  }
  
  return false;
}

bool _checkClassCondition(String condition, int level) {
  if (condition == 'default') return true;
  
  final parts = condition.split(' ');
  if (parts.length != 3) return false;
  
  final stat = parts[0];
  final operator = parts[1];
  final valueStr = parts[2];
  
  final value = int.tryParse(valueStr);
  if (value == null) return false;
  
  if (stat == 'level') {
    if (operator == '>=') return level >= value;
    if (operator == '<=') return level <= value;
    if (operator == '==') return level == value;
  }
  
  return false;
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

List<String> _getUnlockedTitles(Map<String, int> stats, int level) {
  List<String> unlocked = [];
  
  availableTitles.forEach((title, data) {
    if (_checkTitleCondition(data['condition'], stats, level)) {
      unlocked.add(title);
    }
  });
  
  return unlocked;
}

List<String> _getUnlockedClasses(int level) {
  List<String> unlocked = [];
  
  availableClasses.forEach((className, data) {
    if (_checkClassCondition(data['condition'], level)) {
      unlocked.add(className);
    }
  });
  
  return unlocked;
}



  Map<String, int> _getTitleBonuses(String title) {
    final titleData = availableTitles[title];
    if (titleData == null) return {};
    return Map<String, int>.from(titleData['bonuses'] ?? {});
  }

class _ProfileScreenState extends State<ProfileScreen> {
  String playerName = "Carregando...";
  int level = 1;
  String currentJob = "Nenhuma";
  String currentTitle = "Aspirante";
  double hp = 100;
  double maxHp = 100;
  double mp = 50;
  double maxMp = 50;
  int fatigue = 0;
  String? _profileImageUrl;
  double _height = 0;
  double _weight = 0;
  String _biography = "";
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final _cloudinary = CloudinaryPublic(
    'dzs2zzlyu', 
    'Icons-Users',
    cache: false,
  );

  Map<String, int> baseStats = { 'FOR': 10, 'VIT': 10, 'AGI': 10, 'INT': 10, 'PER': 10, };
  Map<String, int> bonusStats = { 'FOR': 0, 'VIT': 0, 'AGI': 0, 'INT': 0, 'PER': 0, };
  Map<String, int> titleBonuses = { 'FOR': 0, 'VIT': 0, 'AGI': 0, 'INT': 0, 'PER': 0, };
  Map<String, int> classBonuses = { 'FOR': 0, 'VIT': 0, 'AGI': 0, 'INT': 0, 'PER': 0, };
  int availableSkillPoints = 0;
  Map<String, int> tempPointsAdded = { 'FOR': 0, 'VIT': 0, 'AGI': 0, 'INT': 0, 'PER': 0, };
  String? previousLevel;

  List<String> unlockedTitles = ["Aspirante"];
  List<String> unlockedClasses = ["Nenhuma"];
  Map<String, bool> completedAchievements = {};

  bool _isLoadingData = true;
  bool _isSaving = false; // Para o botão Salvar

  double currentExp = 0;
  int expToNextLevel = 100;

  List<Item> inventory = [];
  Map<String, String?> equippedItems = {};

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Map<String, int> _getClassBonuses(String className) {
    return _calculateClassBonuses(className, level);
  }

  int _getAchievementBonusForStat(String stat) {
    int bonus = 0;
    completedAchievements.forEach((achievementId, isCompleted) {
      if (isCompleted) {
        final achievement = allPossibleAchievements.firstWhere(
          (ach) => ach.id == achievementId,
          orElse: () => Achievement(id: '', description: '', linkedExerciseId: ''),
        );
        
        if (achievement.statBonuses != null && achievement.statBonuses!.containsKey(stat)) {
          bonus += achievement.statBonuses![stat]!;
        }
      }
    });
    return bonus;
  }

  Future<void> _cleanupInconsistentEquippedItems() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Verificar quais itens equipados não existem no inventário
      List<String> itemsToUnequip = [];
      Set<String> inventoryIds = inventory.map((item) => item.id).toSet();

      equippedItems.forEach((slot, itemId) {
        if (itemId != null && !inventoryIds.contains(itemId)) {
          print("Removendo item inexistente $itemId do slot $slot");
          itemsToUnequip.add(slot);
        }
      });

      if (itemsToUnequip.isNotEmpty) {
        // Atualizar localmente
        setState(() {
          for (String slot in itemsToUnequip) {
            equippedItems[slot] = null;
          }
        });

        // Atualizar no Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'equippedItems': equippedItems});

        print("Limpeza concluída: ${itemsToUnequip.length} itens inconsistentes removidos");
        _recalculateBonusStatsAndHpMp();
      }
    } catch (e) {
      print("Erro ao limpar itens inconsistentes: $e");
    }
  }

  Future<void> _checkAndUnlockNewTitles() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Carregar títulos que já tiveram notificação mostrada
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};
      List<String> titlesWithShownNotification = List<String>.from(data['titlesWithShownNotification'] ?? []);

      List<String> newUnlockedTitles = _getUnlockedTitles(baseStats, level);
      List<String> newlyUnlocked = newUnlockedTitles.where((title) => !unlockedTitles.contains(title)).toList();
      
      if (newlyUnlocked.isNotEmpty) {
        // Calcular EXP total dos novos títulos
        int totalExpGained = 0;
        for (String title in newlyUnlocked) {
          final titleData = availableTitles[title];
          if (titleData != null) {
            totalExpGained += (titleData['expReward'] ?? 0) as int;
          }
        }

        // Atualizar EXP no Firestore se houver
        Map<String, dynamic> updateData = {
          'unlockedTitles': [...unlockedTitles, ...newlyUnlocked],
          'titlesWithShownNotification': [...titlesWithShownNotification, ...newlyUnlocked],
        };

        if (totalExpGained > 0) {
          updateData['exp'] = FieldValue.increment(totalExpGained.toDouble());
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(updateData);

        // Atualizar lista local
        setState(() {
          unlockedTitles.addAll(newlyUnlocked);
          if (totalExpGained > 0) {
            currentExp += totalExpGained;
          }
        });

        // Mostrar notificação apenas para títulos que não tiveram notificação antes
        for (String newTitle in newlyUnlocked) {
          if (!titlesWithShownNotification.contains(newTitle)) {
            await _showNewTitleNotification(newTitle);
          }
        }
      }
    } catch (e) {
      print("Erro ao verificar novos títulos: $e");
    }
  }

  Future<void> _checkAndUnlockNewClasses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Carregar classes que já tiveram notificação mostrada
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};
      List<String> classesWithShownNotification = List<String>.from(data['classesWithShownNotification'] ?? []);

      List<String> newUnlockedClasses = _getUnlockedClasses(level);
      List<String> newlyUnlocked = newUnlockedClasses.where((className) => !unlockedClasses.contains(className)).toList();
      
      if (newlyUnlocked.isNotEmpty) {
        // Salvar classes desbloqueadas no Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'unlockedClasses': [...unlockedClasses, ...newlyUnlocked],
              'classesWithShownNotification': [...classesWithShownNotification, ...newlyUnlocked],
            });

        // Atualizar lista local
        setState(() {
          unlockedClasses.addAll(newlyUnlocked);
        });

        // Mostrar notificação apenas para classes que não tiveram notificação antes
        for (String newClass in newlyUnlocked) {
          if (newClass != "Nenhuma" && !classesWithShownNotification.contains(newClass)) {
            await _showNewClassNotification(newClass);
          }
        }
      }
    } catch (e) {
      print("Erro ao verificar novas classes: $e");
    }
  }

  void _updateUnlockedClasses() {
    setState(() {
      unlockedClasses = _getUnlockedClasses(level);
    });
  }

  Future<void> _showNewClassNotification(String newClass) async {
    if (!mounted) return;
    
    await Future.delayed(const Duration(milliseconds: 500)); // Pequeno delay
    
    await _showStyledDialog(
      context: context,
      titleText: "Nova Classe Desbloqueada!",
      icon: Icons.person_pin,
      iconColor: accentColorPurple,
      contentWidgets: [
        Text(
          "Você desbloqueou a classe:",
          textAlign: TextAlign.center,
          style: const TextStyle(color: textColor, fontSize: 16)
        ),
        const SizedBox(height: 10),
        Text(
          "'$newClass'",
          textAlign: TextAlign.center,
          style: const TextStyle(color: accentColorPurple, fontSize: 20, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 8),
        if (_getClassBonuses(newClass).isNotEmpty)
          Column(
            children: [
              const Text(
                "Bônus da classe:",
                style: TextStyle(color: textColor, fontSize: 14),
              ),
              ..._getClassBonuses(newClass).entries.map((entry) => Text(
                "+${entry.value}% ${entry.key}",
                style: const TextStyle(color: greenStatColor, fontSize: 14, fontWeight: FontWeight.bold),
              )),
            ],
          ),
      ],
      actions: [
        _buildDialogButton(context, "INCRÍVEL!", () => Navigator.of(context).pop(), true),
      ],
    );
  }

  Future<void> _showLevelUpMessage(int previousLevel, int newLevel) async {
    if (!mounted) return;
    
    await _showStyledDialog(
      context: context,
      titleText: "LEVEL UP!",
      icon: Icons.military_tech_rounded,
      iconColor: levelUpColor,
      contentWidgets: [
        Text(
          "Parabéns, $playerName!",
          textAlign: TextAlign.center,
          style: const TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 10),
        Text(
          "Você passou do Nível $previousLevel para o Nível $newLevel!",
          textAlign: TextAlign.center,
          style: const TextStyle(color: textColor, fontSize: 16)
        ),
        const SizedBox(height: 8),
        Text(
          "Você ganhou 3 Pontos de Habilidade!",
          textAlign: TextAlign.center,
          style: const TextStyle(color: greenStatColor, fontSize: 16, fontWeight: FontWeight.bold)
        ),
                 if (newLevel >= 3 && previousLevel < 3)
           const Padding(
             padding: EdgeInsets.only(top: 8.0),
             child: Text(
               "🎉 Você desbloqueou as CLASSES! 🎉",
               textAlign: TextAlign.center,
               style: TextStyle(color: levelUpColor, fontSize: 16, fontWeight: FontWeight.bold)
             ),
           ),
        if (newLevel % 3 == 0 && newLevel >= 3)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              "Agora você pode trocar de classe!",
              textAlign: TextAlign.center,
              style: TextStyle(color: accentColorPurple, fontSize: 14, fontStyle: FontStyle.italic)
            ),
          ),
      ],
      actions: [
        _buildDialogButton(context, "INCRÍVEL!", () => Navigator.of(context).pop(), true),
      ],
    );
  }

  Future<void> _showNewTitleNotification(String newTitle) async {
    if (!mounted) return;
    
    await Future.delayed(const Duration(milliseconds: 500)); // Pequeno delay entre notificações
    
    await _showStyledDialog(
      context: context,
      titleText: "Novo Título Desbloqueado!",
      icon: Icons.military_tech_rounded,
      iconColor: prColor,
      contentWidgets: [
        Text(
          "Você desbloqueou o título:",
          textAlign: TextAlign.center,
          style: const TextStyle(color: textColor, fontSize: 16)
        ),
        const SizedBox(height: 10),
        Text(
          "'$newTitle'",
          textAlign: TextAlign.center,
          style: const TextStyle(color: prColor, fontSize: 20, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 8),
        if (_getTitleBonuses(newTitle).isNotEmpty)
          Column(
            children: [
              const Text(
                "Bônus do título:",
                style: TextStyle(color: textColor, fontSize: 14),
              ),
              ..._getTitleBonuses(newTitle).entries.map((entry) => Text(
                "+${entry.value}% ${entry.key}",
                style: const TextStyle(color: greenStatColor, fontSize: 14, fontWeight: FontWeight.bold),
              )),
            ],
          ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final titleData = availableTitles[newTitle];
            final expReward = titleData?['expReward'] ?? 0;
            if (expReward > 0) {
              return Text(
                "+$expReward EXP",
                style: const TextStyle(color: levelUpColor, fontSize: 16, fontWeight: FontWeight.bold),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
      actions: [
        _buildDialogButton(context, "FANTÁSTICO!", () => Navigator.of(context).pop(), true),
      ],
    );
  }

  int getExpForNextLevel(int currentLvl) {
    if (currentLvl <= 0) return 100; // Caso base para nível 1 ir para 2
    // Fórmula de exemplo: EXP = 100 * (1.35 ^ (nível - 1))
    return (100 * pow(1.35, currentLvl - 1)).round();
  }

  void _recalculateBonusStatsAndHpMp() {
    Map<String, int> currentBonusStats = {'FOR': 0, 'VIT': 0, 'AGI': 0, 'INT': 0, 'PER': 0};
    int bonusMaxMpFromItems = 0;
    int bonusMaxHpFromItems = 0;
    int bonusMaxMpFromTitleClass = 0;
    int bonusMaxHpFromTitleClass = 0;

    // Criar um mapa de IDs válidos para busca mais eficiente
    Map<String, Item> inventoryMap = {for (var item in inventory) item.id: item};
    
    // Calcular bônus dos itens equipados apenas se existirem no inventário
    equippedItems.forEach((slot, itemId) {
      if (itemId != null && inventoryMap.containsKey(itemId)) {
        final item = inventoryMap[itemId]!;
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
    });

    // Calcular bônus de título (em porcentagem)
    titleBonuses = {};
    Map<String, int> rawTitleBonuses = _getTitleBonuses(currentTitle);
    rawTitleBonuses.forEach((statKey, bonusPercentage) {
      if (currentBonusStats.containsKey(statKey)) {
        int baseValue = baseStats[statKey] ?? 0;
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
    classBonuses = {};
    Map<String, int> rawClassBonuses = _getClassBonuses(currentJob);
    rawClassBonuses.forEach((statKey, bonusPercentage) {
      if (currentBonusStats.containsKey(statKey)) {
        int baseValue = baseStats[statKey] ?? 0;
        int calculatedBonus = ((baseValue * bonusPercentage) / 100).round();
        classBonuses[statKey] = calculatedBonus;
        currentBonusStats[statKey] = (currentBonusStats[statKey] ?? 0) + calculatedBonus;
      } else if (statKey == 'MP_MAX_BONUS') {
        bonusMaxMpFromTitleClass += bonusPercentage;
      } else if (statKey == 'HP_MAX_BONUS') {
        bonusMaxHpFromTitleClass += bonusPercentage;
      }
    });

    // Adicionar bônus de conquistas
    completedAchievements.forEach((achievementId, isCompleted) {
      if (isCompleted) {
        // Buscar a conquista na lista global
        final achievement = allPossibleAchievements.firstWhere(
          (ach) => ach.id == achievementId,
          orElse: () => Achievement(id: '', description: '', linkedExerciseId: ''),
        );
        
        if (achievement.statBonuses != null) {
          achievement.statBonuses!.forEach((stat, bonus) {
            if (currentBonusStats.containsKey(stat)) {
              currentBonusStats[stat] = (currentBonusStats[stat] ?? 0) + bonus;
            }
          });
        }
      }
    });

    setState(() {
      bonusStats = currentBonusStats;

      int totalVit = (baseStats['VIT'] ?? 0) + (bonusStats['VIT'] ?? 0);
      int totalInt = (baseStats['INT'] ?? 0) + (bonusStats['INT'] ?? 0);

      maxHp = (totalVit * 10).toDouble() + bonusMaxHpFromItems + bonusMaxHpFromTitleClass;
      hp = maxHp; // Sempre manter HP completo
      if (maxHp <= 0 && totalVit > 0) maxHp = 10;

      maxMp = (totalInt * 5).toDouble() + bonusMaxMpFromItems + bonusMaxMpFromTitleClass;
      mp = maxMp; // Sempre manter MP completo
      if (maxMp <= 0 && totalInt > 0) maxMp = 5;
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (!mounted) return;
        
        // Obter nível anterior salvo no campo específico para controle de level up
        int? savedPreviousLevel = data['previousLevel'];
        int newLevel = data['level'] ?? 1;
        bool hasLeveledUp = savedPreviousLevel != null && newLevel > savedPreviousLevel;
        
        setState(() {
          playerName = data['playerName'] ?? "Jogador";
          level = newLevel;
          currentJob = data['job'] ?? "Nenhuma";
          currentTitle = data['title'] ?? "Aspirante";
          baseStats = Map<String, int>.from(Map<String, dynamic>.from(data['stats'] ?? {}));
          availableSkillPoints = data['availableSkillPoints'] ?? 0;
          currentExp = (data['exp'] ?? 0.0).toDouble();
          hp = (data['currentHP'] ?? 100.0).toDouble();
          maxHp = (data['maxHP'] ?? 100.0).toDouble();
          mp = (data['currentMP'] ?? 50.0).toDouble();
          maxMp = (data['maxMP'] ?? 50.0).toDouble();
          fatigue = data['fatigue'] ?? 0;
          equippedItems = Map<String, String?>.from(data['equippedItems'] ?? {});
          unlockedTitles = List<String>.from(data['unlockedTitles'] ?? ["Aspirante"]);
          unlockedClasses = List<String>.from(data['unlockedClasses'] ?? ["Nenhuma"]);
          completedAchievements = Map<String, bool>.from(data['completedAchievements'] ?? {});
          _profileImageUrl = data['profileImageUrl'];
          _height = (data['height'] ?? 0.0).toDouble();
          _weight = (data['weight'] ?? 0.0).toDouble();
          _biography = data['biography'] ?? "";
        });
        
        // Verificar novos títulos desbloqueados
        await _checkAndUnlockNewTitles();
        
        // Verificar classes desbloqueadas
        await _checkAndUnlockNewClasses();
        _updateUnlockedClasses();
        
        // Carregar inventário após carregar o perfil
        await _loadInventoryItems();
        if (mounted) {
          _recalculateBonusStatsAndHpMp();
          
          // Mostrar mensagem de level up apenas se realmente houve level up
          if (hasLeveledUp) {
            await _showLevelUpMessage(savedPreviousLevel, newLevel);
            
            // Atualizar o previousLevel no Firestore após mostrar a mensagem
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .update({'previousLevel': newLevel});
            } catch (e) {
              print("Erro ao atualizar previousLevel: $e");
            }
          }
        }
      }
    } catch (e) {
      print("Erro ao carregar perfil: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  void _adjustTempPoints(String stat, int amount) {
    if (amount > 0 && availableSkillPoints <= 0) return;
    if (amount < 0 && tempPointsAdded[stat]! <= 0) return;

    setState(() {
      if (amount > 0) {
        tempPointsAdded[stat] = (tempPointsAdded[stat] ?? 0) + 1;
        availableSkillPoints--;
      } else {
        tempPointsAdded[stat] = (tempPointsAdded[stat] ?? 0) - 1;
        availableSkillPoints++;
      }
    });
  }

  bool _hasTempPointsAdded() {
    return tempPointsAdded.values.any((points) => points > 0);
  }

  void _resetTempPoints() {
    setState(() {
      // Devolver os pontos temporários para availableSkillPoints
      int totalTempPoints = tempPointsAdded.values.fold(0, (sum, points) => sum + points);
      availableSkillPoints += totalTempPoints;
      
      // Resetar todos os pontos temporários
      tempPointsAdded = {'FOR': 0, 'VIT': 0, 'AGI': 0, 'INT': 0, 'PER': 0};
    });
  }

  Future<void> _saveSkillPoints() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Atualizar stats base
      Map<String, int> updatedBaseStats = Map<String, int>.from(baseStats);
      tempPointsAdded.forEach((stat, points) {
        if (points > 0) {
          updatedBaseStats[stat] = (updatedBaseStats[stat] ?? 0) + points;
        }
      });

      // Atualizar no Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'stats': updatedBaseStats,
        'availableSkillPoints': availableSkillPoints,
      });

      // Atualizar estado local
      setState(() {
        baseStats = updatedBaseStats;
        tempPointsAdded = {'FOR': 0, 'VIT': 0, 'AGI': 0, 'INT': 0, 'PER': 0};
        _recalculateBonusStatsAndHpMp();
      });

      _showStyledDialog(
        context: context,
        titleText: "Sucesso",
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
        contentWidgets: [
          Text("Atributos atualizados com sucesso!", style: TextStyle(color: textColor)),
        ],
        actions: [
          _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
        ],
      );
    } catch (e) {
      print("Erro ao salvar pontos de atributos: $e");
      _showStyledDialog(
        context: context,
        titleText: "Erro",
        icon: Icons.error_outline,
        iconColor: Colors.red,
        contentWidgets: [
          Text("Erro ao salvar atributos. Tente novamente.", style: TextStyle(color: textColor)),
        ],
        actions: [
          _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), false),
        ],
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Widget _buildDialogButton(BuildContext context, String text, VoidCallback onPressed, bool isPrimary) {
    return ElevatedButton( onPressed: onPressed, style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? accentColorPurple : Colors.grey.shade700, foregroundColor: textColor,
        shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: isPrimary ? accentColorBlue : Colors.transparent)),),
      child: Text(text.toUpperCase()),);
  }

  Future<T?> _showStyledDialog<T>({ required BuildContext context, required String titleText,
    required List<Widget> contentWidgets, required List<Widget> actions,
    IconData icon = Icons.info_outline, Color iconColor = accentColorBlue,
  }) {
    return showDialog<T>( context: context, barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog( backgroundColor: primaryColor.withOpacity(0.95),
          shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(15.0), side: BorderSide(color: accentColorBlue.withOpacity(0.7), width: 1.5),),
          title: Container( padding: const EdgeInsets.only(bottom: 10.0),
            decoration: BoxDecoration( border: Border(bottom: BorderSide(color: accentColorPurple.withOpacity(0.5), width: 1.0))),
            child: Row(children: [ Icon(icon, color: iconColor), const SizedBox(width: 10), Text(titleText.toUpperCase(),
                  style: const TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),), ],),),
          content: SingleChildScrollView( child: ListBody(children: contentWidgets),),
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
  
  void _showTitleSelectionDialog() {
    _showStyledDialog(
      context: context,
      titleText: "Selecionar Título",
      icon: Icons.military_tech_rounded,
      iconColor: Colors.orangeAccent,
      contentWidgets: unlockedTitles.isEmpty 
        ? [const Text("Nenhum título desbloqueado ainda.", style: TextStyle(color: textColor))]
        : unlockedTitles.map((titleOption) {
                    final titleBonuses = _getTitleBonuses(titleOption);
        return Column(
          children: [
            RadioListTile<String>(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titleOption, style: const TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                  if (titleBonuses.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "Bônus: ${titleBonuses.entries.map((e) => "+${e.value}% ${e.key}").join(", ")}",
                        style: TextStyle(color: greenStatColor, fontSize: 12),
                      ),
                    ),
                ],
              ),
                  value: titleOption,
                  groupValue: currentTitle,
                  onChanged: (String? value) async {
                    if (value != null) { 
                      setState(() { currentTitle = value; });
                      Navigator.of(context).pop();
                      
                      // Salvar automaticamente no Firestore
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .update({'title': currentTitle});
                          _recalculateBonusStatsAndHpMp(); // Recalcular bônus
                          print("Título '$currentTitle' salvo automaticamente");
                        }
                      } catch (e) {
                        print("Erro ao salvar título: $e");
                      }
                    }
                  },
                  activeColor: accentColorPurple,
                  contentPadding: EdgeInsets.zero,
                ),
                if (titleOption != unlockedTitles.last)
                  Divider(color: accentColorBlue.withOpacity(0.3), height: 1),
              ],
            );
          }).toList(),
      actions: [_buildDialogButton(context, "Fechar", () => Navigator.of(context).pop(), false)],
    );
  }

  void _showClassSelectionDialog() {
    // Verificar se pode usar classes (desbloqueadas a partir do nível 3)
    if (level < 3) {
      _showStyledDialog(
        context: context,
        titleText: "Classes Bloqueadas",
        icon: Icons.lock_outline,
        iconColor: Colors.redAccent,
        contentWidgets: [
          Text(
            "Você precisa atingir o nível 3 para desbloquear as classes!",
            textAlign: TextAlign.center,
            style: const TextStyle(color: textColor, fontSize: 16)
          ),
          const SizedBox(height: 8),
          Text(
            "Nível atual: $level/3",
            textAlign: TextAlign.center,
            style: const TextStyle(color: accentColorBlue, fontSize: 14)
          ),
        ],
        actions: [_buildDialogButton(context, "Entendi", () => Navigator.of(context).pop(), true)],
      );
      return;
    }

    _showStyledDialog(
      context: context,
      titleText: "Selecionar Classe",
      icon: Icons.person_pin,
      iconColor: accentColorPurple,
      contentWidgets: unlockedClasses.map((classOption) {
        final classBonuses = _getClassBonuses(classOption);
        return Column(
          children: [
            RadioListTile<String>(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(classOption, style: const TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                  if (classBonuses.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "Bônus: ${classBonuses.entries.map((e) => "+${e.value}% ${e.key}").join(", ")}",
                        style: TextStyle(color: greenStatColor, fontSize: 12),
                      ),
                    ),
                ],
              ),
              value: classOption,
              groupValue: currentJob,
              onChanged: (String? value) async {
                if (value != null) { 
                  setState(() { currentJob = value; });
                  Navigator.of(context).pop();
                  
                  // Salvar automaticamente no Firestore
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .update({'job': currentJob});
                      _recalculateBonusStatsAndHpMp(); // Recalcular bônus
                      print("Classe '$currentJob' salva automaticamente");
                    }
                  } catch (e) {
                    print("Erro ao salvar classe: $e");
                  }
                }
              },
              activeColor: accentColorPurple,
              contentPadding: EdgeInsets.zero,
            ),
            if (classOption != unlockedClasses.last)
              Divider(color: accentColorBlue.withOpacity(0.3), height: 1),
          ],
        );
      }).toList(),
      actions: [_buildDialogButton(context, "Fechar", () => Navigator.of(context).pop(), false)],
    );
  }

  void _showItemSelectionDialog(String slotName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Marcar todos os itens como não novos ao abrir o diálogo
      final batch = FirebaseFirestore.instance.batch();
      for (var item in inventory.where((item) => item.isNew)) {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('inventory')
            .doc(item.id);
        batch.update(docRef, {'isNew': false});
      }
      await batch.commit();

      // Atualizar o estado local
      setState(() {
        for (var item in inventory) {
          item.isNew = false;
        }
      });
    } catch (e) {
      print("Erro ao marcar itens como não novos: $e");
    }

    List<Item> itemsForSlot = inventory.where((item) => item.slotType == slotName).toList();
    List<Widget> dialogItems = itemsForSlot.map((item) => ListTile(
      leading: Icon(item.icon, color: itemRankColors[item.rank] ?? accentColorBlue),
      title: Text(item.name, style: TextStyle(color: itemRankColors[item.rank] ?? textColor)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Rank: ${item.rank}", style: TextStyle(color: itemRankColors[item.rank] ?? textColor.withOpacity(0.7), fontWeight: FontWeight.bold)),
          if (item.statBonuses.isNotEmpty)
            Text(
              item.statBonuses.entries.map((e) => "${e.key}: +${e.value}").join(", "),
              style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
            ),
        ],
      ),
      trailing: item.isNew ? const Icon(Icons.star, color: Colors.yellowAccent, size: 16) : null,
      onTap: () async {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;

          setState(() { 
            equippedItems[slotName] = item.id; 
            _recalculateBonusStatsAndHpMp();
          });
          
          // Salvar automaticamente no Firestore
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({
                  'equippedItems': equippedItems,
                  'bonusStats': bonusStats,
                });
            print("Item '${item.name}' equipado e salvo automaticamente em '$slotName'");
          } catch (e) {
            print("Erro ao salvar item equipado: $e");
          }
          
          Navigator.of(context).pop(); 
          print("Stats recalculados: $bonusStats");
        } catch (e) {
          print("Erro ao equipar item: $e");
          if (mounted) {
            _showStyledDialog(
              context: context,
              titleText: "Erro",
              icon: Icons.error_outline,
              iconColor: Colors.red,
              contentWidgets: [
                Text("Erro ao equipar item: $e", style: TextStyle(color: textColor)),
              ],
              actions: [
                _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), false),
              ],
            );
          }
        }
      },
    )).toList();

    if (equippedItems[slotName] != null) {
      dialogItems.insert(0, ListTile(
        leading: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
        title: const Text("Desequipar Item", style: TextStyle(color: Colors.redAccent)),
        onTap: () async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;
          
          setState(() {
            equippedItems[slotName] = null;
            _recalculateBonusStatsAndHpMp();
          });
          
          // Salvar automaticamente no Firestore
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({
                  'equippedItems': equippedItems,
                  'bonusStats': bonusStats,
                });
            print("Item desequipado e salvo automaticamente do slot '$slotName'");
          } catch (e) {
            print("Erro ao salvar desequipamento: $e");
          }
          
          Navigator.of(context).pop();
          print("Stats recalculados após desequipar: $bonusStats");
        },
      ));
    }
    
    if (dialogItems.isEmpty || (itemsForSlot.isEmpty && equippedItems[slotName] == null)) {
      dialogItems = [const Center(child: Padding( padding: EdgeInsets.all(16.0),
        child: Text("Nenhum item disponível para este slot.", style: TextStyle(color: textColor)),
      ))];
    }

    _showStyledDialog(
      context: context, titleText: "Equipar em: $slotName", icon: Icons.inventory_2_outlined,
      contentWidgets: dialogItems,
      actions: [_buildDialogButton(context, "Fechar", () => Navigator.of(context).pop(), false)],);
  }

  Widget _buildStatsSection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Atributos",
            style: TextStyle(
              color: accentColorBlue,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: panelBgColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColorBlue.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                // Força
                _buildStatRow(
                  'FOR',
                  baseStats['FOR']!,
                  bonusStats['FOR']!,
                  Icons.fitness_center,
                  Colors.red,
                ),
                Divider(color: accentColorBlue.withOpacity(0.2), height: 16),
                // Vitalidade
                _buildStatRow(
                  'VIT',
                  baseStats['VIT']!,
                  bonusStats['VIT']!,
                  Icons.favorite,
                  Colors.green,
                ),
                Divider(color: accentColorBlue.withOpacity(0.2), height: 16),
                // Agilidade
                _buildStatRow(
                  'AGI',
                  baseStats['AGI']!,
                  bonusStats['AGI']!,
                  Icons.directions_run,
                  Colors.blue,
                ),
                Divider(color: accentColorBlue.withOpacity(0.2), height: 16),
                // Inteligência
                _buildStatRow(
                  'INT',
                  baseStats['INT']!,
                  bonusStats['INT']!,
                  Icons.psychology,
                  Colors.purple,
                ),
                Divider(color: accentColorBlue.withOpacity(0.2), height: 16),
                // Percepção
                _buildStatRow(
                  'PER',
                  baseStats['PER']!,
                  bonusStats['PER']!,
                  Icons.visibility,
                  Colors.amber,
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _hasTempPointsAdded() 
                  ? levelUpColor.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasTempPointsAdded() 
                    ? levelUpColor.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pontos Disponíveis: $availableSkillPoints",
                        style: TextStyle(
                          color: _hasTempPointsAdded() ? levelUpColor : textColor.withOpacity(0.7),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (_hasTempPointsAdded())
                        Text(
                          "Você tem alterações não salvas",
                          style: TextStyle(
                            color: yellowWarningColor,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_hasTempPointsAdded())
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: _isSaving ? null : _resetTempPoints,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade700,
                          foregroundColor: textColor,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size(80, 36),
                        ),
                        child: Text("RESETAR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveSkillPoints,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: levelUpColor,
                          foregroundColor: Colors.black87,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size(80, 36),
                        ),
                        child: _isSaving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                                ),
                              )
                            : Text("SALVAR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String stat, int base, int bonus, IconData icon, Color color) {
    int itemBonus = 0;
    int titleBonus = titleBonuses[stat] ?? 0;
    int classBonus = classBonuses[stat] ?? 0;
    int tempBonus = tempPointsAdded[stat]!;
    
    // Calcular bônus apenas dos itens (excluindo título e classe)
    Map<String, Item> inventoryMap = {for (var item in inventory) item.id: item};
    equippedItems.forEach((slot, itemId) {
      if (itemId != null && inventoryMap.containsKey(itemId)) {
        final item = inventoryMap[itemId]!;
        itemBonus += item.statBonuses[stat] ?? 0;
      }
    });
    
    int total = base + itemBonus + titleBonus + classBonus + tempBonus;
    bool hasTempPoints = tempBonus > 0;
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Wrap(
                  spacing: 6,
                  children: [
                    Text(
                      "Base: $base",
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                    if (itemBonus > 0)
                      Text(
                        "Item: +$itemBonus",
                        style: TextStyle(
                          color: accentColorBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (titleBonus > 0)
                      Text(
                        "Título: +$titleBonus",
                        style: TextStyle(
                          color: prColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (classBonus > 0)
                      Text(
                        "Classe: +$classBonus",
                        style: TextStyle(
                          color: accentColorPurple,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Text(
            "$total",
            style: TextStyle(
              color: hasTempPoints ? levelUpColor : textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (availableSkillPoints > 0) ...[
            SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.remove_circle_outline, color: accentColorBlue),
                  onPressed: tempPointsAdded[stat]! > 0 ? () => _adjustTempPoints(stat, -1) : null,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                SizedBox(width: 4),
                Text(
                  "${tempPointsAdded[stat]}",
                  style: TextStyle(
                    color: levelUpColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: accentColorBlue),
                  onPressed: availableSkillPoints > 0 ? () => _adjustTempPoints(stat, 1) : null,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double value, double maxValue, Color barColor) { 
    final double percentage = (maxValue > 0 && value >= 0) ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    // O label principal da barra (XP, HP, MP)
    String mainLabel = label;
    if (label == "XP: ${currentExp.toInt()}/${expToNextLevel.toInt()}") { // Para o caso da XP
      mainLabel = "XP";
    } else if (label == "HP") { // Para HP
      mainLabel = "HP";
    } else if (label == "MP") { // Para MP
      mainLabel = "MP";
    }

    return Padding( padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Column( crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(mainLabel, style: const TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 1),
          Stack(children: [
              Container(height: 7, decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(3.5),),),
              FractionallySizedBox(widthFactor: percentage, child: Container(height: 7, decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(3.5),
                          boxShadow: [ BoxShadow( color: barColor.withOpacity(0.5), blurRadius: 2.0, spreadRadius: 0.2,)]),),),],),
        ],));}
  
  Widget _buildEquipmentColumn({required bool isLeft}) {
    final List<Map<String, dynamic>> slotData = isLeft
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
    return SizedBox(width: 100,
      child: Column( mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: slotData.map((slot) {
          final String slotType = slot['type'] as String;
          final bool isEquippedCurrent = equippedItems[slotType] != null;
          final bool hasNewCurrent = inventory.any((item) => item.slotType == slotType && item.isNew && equippedItems[slotType] != item.id);
          
          Map<String, dynamic>? equippedItemData;
          if (equippedItems[slotType] != null) {
            // Busca segura sem usar firstWhere que pode gerar exceção
            final item = inventory.where((item) => item.id == equippedItems[slotType]).firstOrNull;
            if (item != null) {
              equippedItemData = {
                'id': item.id,
                'name': item.name,
                'rank': item.rank,
                'slotType': item.slotType,
                'icon': item.icon,
                'statBonuses': item.statBonuses,
              };
            }
            // Se item for null, equippedItemData permanece null e mostra placeholder
          }

          return EquipmentSlotWidget(
            slotName: slot['name'],
            placeholderIcon: slot['icon'],
            hasNewItem: hasNewCurrent,
            isEquipped: isEquippedCurrent,
            equippedItem: equippedItemData,
            onTap: () => _showItemSelectionDialog(slotType),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _loadInventoryItems() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final inventorySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .orderBy('acquiredAt', descending: true)
          .get();

      if (!mounted) return;

      setState(() {
        inventory = inventorySnapshot.docs.map((doc) {
          final data = doc.data();
          return Item(
            id: doc.id,
            name: data['name'] ?? 'Item Desconhecido',
            slotType: data['type'] ?? 'Desconhecido',
            rank: data['rank'] ?? 'E',
            dateAcquired: (data['acquiredAt'] as Timestamp).toDate(),
            icon: _getIconForSlotType(data['type'] ?? 'Desconhecido'),
            isNew: data['isNew'] ?? true,
            statBonuses: Map<String, int>.from(data['statBonuses'] ?? {}),
          );
        }).toList();
      });

      // Limpar itens equipados inconsistentes após carregar o inventário
      await _cleanupInconsistentEquippedItems();
    } catch (e) {
      print('Erro ao carregar inventário: $e');
    }
  }

  IconData _getIconForSlotType(String slotType) {
    switch (slotType) {
      case 'Cabeça':
        return Icons.account_circle_outlined;
      case 'Peitoral':
        return Icons.shield_outlined;
      case 'Pernas':
        return Icons.accessibility_new_outlined;
      case 'Pés':
        return Icons.do_not_step;
      case 'Mão Direita':
      case 'Mão Esquerda':
        return Icons.pan_tool_alt_outlined;
      case 'Orelhas':
        return Icons.earbuds_outlined;
      case 'Colar':
        return Icons.circle_outlined;
      case 'Rosto':
        return Icons.face_retouching_natural_outlined;
      case 'Bracelete':
        return Icons.watch_later_outlined;
      case 'Acessório E.':
      case 'Acessório D.':
        return Icons.star_border_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
                    if (mounted) {
                _showStyledDialog(
                  context: context,
                  titleText: "Erro",
                  icon: Icons.error_outline,
                  iconColor: Colors.red,
                  contentWidgets: [
                    Text("Erro ao selecionar imagem: $e", style: TextStyle(color: textColor)),
                  ],
                  actions: [
                    _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), false),
                  ],
                );
              }
    }
  }

  Future<String?> _uploadImage(XFile imageFile) async {
    try {
      CloudinaryFile cloudinaryFile;
      
      if (kIsWeb) {
        // No web, usar bytes
        final bytes = await imageFile.readAsBytes();
        cloudinaryFile = CloudinaryFile.fromBytesData(
          bytes,
          identifier: imageFile.name,
          resourceType: CloudinaryResourceType.Image,
        );
      } else {
        // No mobile, usar path
        cloudinaryFile = CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
        );
      }

      final response = await _cloudinary.uploadFile(cloudinaryFile);
      return response.secureUrl;
    } on CloudinaryException {
      return null;
    } catch (e) {
      return null;
    }
  }

  void _showChangeProfileImageDialog() {
    _showStyledDialog(
      context: context,
      titleText: "Alterar Foto de Perfil",
      icon: Icons.camera_alt_rounded,
      iconColor: accentColorPurple,
      contentWidgets: [
        Text(
          "Escolha uma nova foto de perfil:",
          style: TextStyle(color: textColor, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        // Preview da imagem atual ou selecionada
        Center(
          child: Container(
            width: 120,
            height: 120,
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
              child: _selectedImage != null
                  ? (kIsWeb
                      ? FutureBuilder<Uint8List>(
                          future: _selectedImage!.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              );
                            } else {
                              return CircularProgressIndicator(color: accentColorPurple);
                            }
                          },
                        )
                      : Image.file(
                          File(_selectedImage!.path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ))
                  : (_profileImageUrl != null
                      ? Image.network(
                          _profileImageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            size: 60,
                            color: accentColorBlue.withOpacity(0.7),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 60,
                          color: accentColorBlue.withOpacity(0.7),
                        )),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Botão para selecionar imagem
        Center(
          child: ElevatedButton.icon(
            onPressed: () async {
              await _pickImage();
              Navigator.of(context).pop(); // Fechar o dialog atual
              _showChangeProfileImageDialog(); // Reabrir com a nova imagem
            },
            icon: Icon(Icons.photo_library, size: 18),
            label: Text("Escolher da Galeria"),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColorBlue,
              foregroundColor: textColor,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
      ],
      actions: [
        if (_selectedImage != null) ...[
          _buildDialogButton(
            context,
            "Salvar",
            () async {
              try {
                // Mostrar loading
                Navigator.of(context).pop();
                _showStyledDialog(
                  context: context,
                  titleText: "Salvando...",
                  icon: Icons.cloud_upload,
                  iconColor: accentColorBlue,
                  contentWidgets: [
                    Center(
                      child: Column(
                        children: const [
                          CircularProgressIndicator(color: accentColorPurple),
                          SizedBox(height: 16),
                          Text(
                            "Fazendo upload da imagem...",
                            style: TextStyle(color: textColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                  actions: [],
                );

                String? imageUrl = await _uploadImage(_selectedImage!);
                Navigator.of(context).pop(); // Fechar loading

                if (imageUrl != null) {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'profileImageUrl': imageUrl});

                    setState(() {
                      _profileImageUrl = imageUrl;
                      _selectedImage = null;
                    });

                    _showStyledDialog(
                      context: context,
                      titleText: "Sucesso",
                      icon: Icons.check_circle_outline,
                      iconColor: Colors.green,
                      contentWidgets: [
                        Text("Foto de perfil atualizada com sucesso!", style: TextStyle(color: textColor)),
                      ],
                      actions: [
                        _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
                      ],
                    );
                  }
                } else {
                  _showStyledDialog(
                    context: context,
                    titleText: "Erro",
                    icon: Icons.error_outline,
                    iconColor: Colors.red,
                    contentWidgets: [
                      Text("Erro ao fazer upload da imagem. Tente novamente.", style: TextStyle(color: textColor)),
                    ],
                    actions: [
                      _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), false),
                    ],
                  );
                }
              } catch (e) {
                Navigator.of(context).pop(); // Fechar loading se ainda estiver aberto
                _showStyledDialog(
                  context: context,
                  titleText: "Erro",
                  icon: Icons.error_outline,
                  iconColor: Colors.red,
                  contentWidgets: [
                    Text("Erro ao salvar foto: $e", style: TextStyle(color: textColor)),
                  ],
                  actions: [
                    _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), false),
                  ],
                );
              }
            },
            true,
          ),
          _buildDialogButton(
            context,
            "Cancelar",
            () {
              setState(() {
                _selectedImage = null;
              });
              Navigator.of(context).pop();
            },
            false,
          ),
        ] else ...[
          _buildDialogButton(
            context,
            "Fechar",
            () => Navigator.of(context).pop(),
            false,
          ),
        ],
      ],
    );
  }

  void _showEditBiographyDialog() {
    final TextEditingController bioController = TextEditingController(text: _biography);
    const int maxBioLength = 200;

    _showStyledDialog(
      context: context,
      titleText: "Editar Biografia",
      icon: Icons.edit_note_rounded,
      iconColor: accentColorBlue,
      contentWidgets: [
        Text(
          "Conte um pouco sobre você:",
          style: TextStyle(color: textColor, fontSize: 14),
        ),
        const SizedBox(height: 10),
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentColorBlue.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: bioController,
                    style: const TextStyle(color: textColor),
                    maxLines: 4,
                    maxLength: maxBioLength,
                    decoration: InputDecoration(
                      hintText: 'Escreva sua biografia aqui...',
                      hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                      border: InputBorder.none,
                      counterStyle: TextStyle(color: textColor.withOpacity(0.7)),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${bioController.text.length}/$maxBioLength caracteres",
                  style: TextStyle(
                    color: bioController.text.length > maxBioLength 
                        ? Colors.red 
                        : textColor.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            );
          }
        ),
      ],
      actions: [
        _buildDialogButton(
          context,
          "Salvar",
          () async {
            if (bioController.text.length > maxBioLength) {
              _showStyledDialog(
                context: context,
                titleText: "Erro",
                icon: Icons.error_outline,
                iconColor: Colors.red,
                contentWidgets: [
                  Text("Biografia muito longa. Máximo de $maxBioLength caracteres.", style: TextStyle(color: textColor)),
                ],
                actions: [
                  _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
                ],
              );
              return;
            }

            try {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({'biography': bioController.text.trim()});

                setState(() {
                  _biography = bioController.text.trim();
                });

                Navigator.of(context).pop();
                _showStyledDialog(
                  context: context,
                  titleText: "Sucesso",
                  icon: Icons.check_circle_outline,
                  iconColor: Colors.green,
                  contentWidgets: [
                    Text("Biografia atualizada com sucesso!", style: TextStyle(color: textColor)),
                  ],
                  actions: [
                    _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
                  ],
                );
              }
            } catch (e) {
              _showStyledDialog(
                context: context,
                titleText: "Erro",
                icon: Icons.error_outline,
                iconColor: Colors.red,
                contentWidgets: [
                  Text("Erro ao salvar biografia: $e", style: TextStyle(color: textColor)),
                ],
                actions: [
                  _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), false),
                ],
              );
            }
          },
          true,
        ),
        _buildDialogButton(
          context,
          "Cancelar",
          () => Navigator.of(context).pop(),
          false,
        ),
      ],
    );
  }

  void _showEditPhysicalInfoDialog() {
    final TextEditingController heightController = TextEditingController(text: _height.toString());
    final TextEditingController weightController = TextEditingController(text: _weight.toString());

    _showStyledDialog(
      context: context,
      titleText: "Editar Informações Físicas",
      icon: Icons.straighten_rounded,
      iconColor: accentColorBlue,
      contentWidgets: [
        Text(
          "Atualize suas informações físicas:",
          style: TextStyle(color: textColor, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        // Campos de Altura e Peso
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: heightController,
                style: const TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Altura (m)',
                  labelStyle: const TextStyle(color: textColor),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: weightController,
                style: const TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Peso (kg)',
                  labelStyle: const TextStyle(color: textColor),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
      actions: [
        _buildDialogButton(
          context,
          "Salvar",
          () async {
            try {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                double newHeight = double.tryParse(heightController.text) ?? _height;
                double newWeight = double.tryParse(weightController.text) ?? _weight;
                
                if (newHeight == _height && newWeight == _weight) {
                  _showStyledDialog(
                    context: context,
                    titleText: "Informação",
                    icon: Icons.info_outline,
                    iconColor: Colors.orange,
                    contentWidgets: [
                      Text("Não há alterações a serem salvas.", style: TextStyle(color: textColor)),
                    ],
                    actions: [
                      _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), false),
                    ],
                  );
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({
                      'height': newHeight,
                      'weight': newWeight,
                    });

                setState(() {
                  _height = newHeight;
                  _weight = newWeight;
                });

                Navigator.of(context).pop();
                _showStyledDialog(
                  context: context,
                  titleText: "Sucesso",
                  icon: Icons.check_circle_outline,
                  iconColor: Colors.green,
                  contentWidgets: [
                    Text("Informações físicas atualizadas com sucesso!", style: TextStyle(color: textColor)),
                  ],
                  actions: [
                    _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
                  ],
                );
              }
            } catch (e) {
              _showStyledDialog(
                context: context,
                titleText: "Erro",
                icon: Icons.error_outline,
                iconColor: Colors.red,
                contentWidgets: [
                  Text("Erro ao salvar alterações: $e", style: TextStyle(color: textColor)),
                ],
                actions: [
                  _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), false),
                ],
              );
            }
          },
          true,
        ),
        _buildDialogButton(
          context,
          "Cancelar",
          () => Navigator.of(context).pop(),
          false,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold( backgroundColor: primaryColor,
        appBar: AppBar(title: const Text("CARREGANDO STATUS...", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, letterSpacing: 1.5)), centerTitle: true, backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: accentColorBlue), automaticallyImplyLeading: false,),
        body: const Center(child: CircularProgressIndicator(color: accentColorPurple)),);
    }
    
    expToNextLevel = getExpForNextLevel(level); 

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar( backgroundColor: Colors.transparent, elevation: 0,
        title: Text(playerName, style: TextStyle(color: accentColorBlue, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.0,)),
        centerTitle: true, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: accentColorBlue),
            onPressed: () => Navigator.of(context).pop(),),),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('inventory')
            .orderBy('acquiredAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar inventário: ${snapshot.error}'));
          }

          if (snapshot.hasData) {
            inventory = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Item(
                id: doc.id,
                name: data['name'] ?? 'Item Desconhecido',
                slotType: data['type'] ?? 'Desconhecido',
                rank: data['rank'] ?? 'E',
                dateAcquired: (data['acquiredAt'] as Timestamp).toDate(),
                icon: _getIconForSlotType(data['type'] ?? 'Desconhecido'),
                isNew: data['isNew'] ?? true,
                statBonuses: Map<String, int>.from(data['statBonuses'] ?? {}),
              );
            }).toList();
            
            // Recalcular bônus após atualizar inventário
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _recalculateBonusStatsAndHpMp();
            });
          }

          return Center(
            child: Container( margin: const EdgeInsets.all(8.0), padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration( borderRadius: BorderRadius.circular(10.0),
                  gradient: LinearGradient( colors: [accentColorBlue.withOpacity(0.6), accentColorPurple.withOpacity(0.6)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,),
                  boxShadow: [ BoxShadow( color: accentColorPurple.withOpacity(0.3), blurRadius: 6.0,) ] ),
              child: Container( padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration( color: primaryColor.withOpacity(0.95), borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: accentColorBlue.withOpacity(0.4))),
                child: SingleChildScrollView(
                  child: Column( mainAxisSize: MainAxisSize.min, children: [
                      Row( crossAxisAlignment: CrossAxisAlignment.center, children: [
                          Text("$level", style: TextStyle( color: accentColorBlue, fontSize: 44, fontWeight: FontWeight.bold, 
                               shadows: [ Shadow( color: accentColorBlue.withOpacity(0.5), blurRadius: 7.0,)],),),
                          const SizedBox(width: 8),
                          Expanded(child: Column( crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                                                  Text("LEVEL", style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 9, letterSpacing: 0.8),),
                Row(children: [
                    Expanded(child: Text("CLASSE: $currentJob", style: const TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis,)),
                    TextButton( style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size(45,25), tapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact),
                      onPressed: _showClassSelectionDialog, 
                      child: Text(level >= 3 ? "Alterar" : "Nível 3", style: TextStyle(color: level >= 3 ? accentColorPurple : Colors.grey, fontSize: 9)))]),
                Row(children: [
                    Expanded(child: Text("TÍTULO: $currentTitle", style: const TextStyle(color: textColor, fontSize: 10, fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis,)),
                    TextButton( style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size(45,25), tapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact),
                      onPressed: _showTitleSelectionDialog, 
                      child: Text("Alterar", style: TextStyle(color: accentColorPurple, fontSize: 9)))])],),),],),
                      const SizedBox(height: 10),
                      // Imagem do Perfil e Informações Físicas
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _showChangeProfileImageDialog,
                            child: Container(
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
                              child: Stack(
                                children: [
                                  ClipOval(
                                    child: _profileImageUrl != null
                                        ? Image.network(
                                            _profileImageUrl!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
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
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: accentColorPurple,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: primaryColor, width: 2),
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
                                        size: 12,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Toque na foto para alterar",
                                style: TextStyle(
                                  color: accentColorPurple.withOpacity(0.8),
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 8),
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
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size(45, 25),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: _showEditPhysicalInfoDialog,
                                    child: Text(
                                      "Altura/Peso",
                                      style: TextStyle(color: accentColorBlue, fontSize: 9),
                                    ),
                                  ),
                                  Text(" | ", style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 9)),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size(45, 25),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: _showEditBiographyDialog,
                                    child: Text(
                                      "Biografia",
                                      style: TextStyle(color: accentColorPurple, fontSize: 9),
                                    ),
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
                      _buildProgressBar("XP", currentExp, expToNextLevel.toDouble(), Colors.lightGreenAccent.shade700),
                      Padding(padding: const EdgeInsets.only(left: 2.0, bottom: 3.0), child: Text( "${currentExp.toInt()}/${expToNextLevel.toInt()} EXP",
                          style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 9),),),
                      Divider(color: accentColorBlue.withOpacity(0.5), height: 12, thickness: 0.3),
                      _buildProgressBar("HP", hp, maxHp, Colors.redAccent),
                      Padding(padding: const EdgeInsets.only(left: 2.0, bottom: 3.0), child: Text( "${hp.toInt()}/${maxHp.toInt()} HP", style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 9),),),
                      _buildProgressBar("MP", mp, maxMp, Colors.blueAccent),
                      Padding(padding: const EdgeInsets.only(left: 2.0, bottom: 3.0), child: Text( "${mp.toInt()}/${maxMp.toInt()} MP", style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 9),),),
                      Divider(color: accentColorBlue.withOpacity(0.5), height: 12, thickness: 0.3),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18.0),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.whatshot_rounded, color: prColor, size: 32, shadows: [Shadow(color: prColor.withOpacity(0.3), blurRadius: 8)]),
                              const SizedBox(height: 6),
                              Text(
                                "AURA TOTAL",
                                style: TextStyle(
                                  color: accentColorBlue,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  shadows: [Shadow(color: accentColorBlue.withOpacity(0.2), blurRadius: 6)],
                                ),
                              ),
                              Text(
                                "${aura_utils.calculateTotalAura(
                                  baseStats: baseStats,
                                  bonusStats: {
                                    'FOR': ((bonusStats['FOR'] ?? 0) - _getAchievementBonusForStat('FOR')),
                                    'VIT': ((bonusStats['VIT'] ?? 0) - _getAchievementBonusForStat('VIT')),
                                    'AGI': ((bonusStats['AGI'] ?? 0) - _getAchievementBonusForStat('AGI')),
                                    'INT': ((bonusStats['INT'] ?? 0) - _getAchievementBonusForStat('INT')),
                                    'PER': ((bonusStats['PER'] ?? 0) - _getAchievementBonusForStat('PER')),
                                  },
                                  currentTitle: currentTitle,
                                  currentJob: currentJob,
                                  level: level,
                                  completedAchievements: completedAchievements,
                                )}",
                                style: TextStyle(
                                  color: prColor,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: prColor.withOpacity(0.3), blurRadius: 10)],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      Divider(color: accentColorBlue.withOpacity(0.5), height: 12, thickness: 0.3),

                      // STATS
                      _buildStatsSection(),

                      Divider(color: accentColorBlue.withOpacity(0.5), height: 18, thickness: 0.3),
                      const Text("EQUIPAMENTOS", style: TextStyle(color: accentColorBlue, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      const SizedBox(height: 6),
                      Padding( padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row( crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _buildEquipmentColumn(isLeft: true),
                            const Spacer(),
                            _buildEquipmentColumn(isLeft: false), ],),),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}