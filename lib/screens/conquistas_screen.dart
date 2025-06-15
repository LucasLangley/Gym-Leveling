// Em lib/screens/conquistas_screen.dart
// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/translation_service.dart';

// Cores (assumindo que são as mesmas do seu projeto)
const Color primaryColor = Color(0xFF0A0E21);
const Color accentColorBlue = Color(0xFF40C4FF);
const Color accentColorPurple = Color(0xFF8A2BE2);
const Color textColor = Colors.white;
const Color panelBgColor = Color(0x991D1E33);
const Color achievementColor =
    Colors.amberAccent; // Cor para ícone de conquista

// Classe Achievement (mantida para definir a estrutura dos dados)
// A lista `allPossibleAchievements` agora estará no treino_screen.dart ou um arquivo global
// Aqui, só precisamos da definição da classe para tipagem, ou podemos importá-la.
// Para este exemplo, vou manter a definição da classe aqui, mas a lista de conquistas
// será carregada do Firebase.
class Achievement {
  final String id;
  final String description;
  final int expReward;
  final String? titleReward;
  final String
      linkedExerciseId; // Importante para referência, mesmo que não usado diretamente na UI aqui
  final double? weightCondition;
  final int? repsCondition;
  final int? durationCondition;
  final Map<String, int>? statBonuses; // Bônus de atributos permanentes
  bool isCompleted;

  Achievement({
    required this.id,
    required this.description,
    required this.linkedExerciseId,
    this.expReward = 0,
    this.titleReward,
    this.weightCondition,
    this.repsCondition,
    this.durationCondition,
    this.statBonuses,
    this.isCompleted = false,
  });
}

// Lista mestre de todas as conquistas possíveis no jogo.
// Esta lista define as conquistas que o app conhece.
// O status de completude virá do Firebase.
// Esta lista pode ser movida para um arquivo de constantes/configurações.
final List<Achievement> allPossibleAchievements = [
  // Conquistas de Força
  Achievement(
      id: 'ach_supino_100kg',
      description: "achSupino100kgDesc",
      linkedExerciseId: 'sup_r',
      weightCondition: 100,
      repsCondition: 1,
      expReward: 500,
      titleReward: "achSupino100kgTitle",
      statBonuses: {'FOR': 5}),
  Achievement(
      id: 'ach_supino_50kg',
      description: "achSupino50kgDesc",
      linkedExerciseId: 'sup_r',
      weightCondition: 50,
      repsCondition: 1,
      expReward: 200,
      titleReward: "achSupino50kgTitle",
      statBonuses: {'FOR': 2}),
  Achievement(
      id: 'ach_agachamento_150kg',
      description: "achAgachamento150kgDesc",
      linkedExerciseId: 'agachamento_livre',
      weightCondition: 150,
      repsCondition: 1,
      expReward: 750,
      titleReward: "achAgachamento150kgTitle",
      statBonuses: {'FOR': 5, 'VIT': 3}),
  Achievement(
      id: 'ach_agachamento_80kg',
      description: "achAgachamento80kgDesc",
      linkedExerciseId: 'agachamento_livre',
      weightCondition: 80,
      repsCondition: 1,
      expReward: 300,
      titleReward: "achAgachamento80kgTitle",
      statBonuses: {'FOR': 3}),
  Achievement(
      id: 'ach_50_flexoes',
      description: "ach50FlexoesDesc",
      linkedExerciseId: 'flexao_tradicional',
      repsCondition: 50,
      expReward: 200,
      titleReward: "ach50FlexoesTitle",
      statBonuses: {'FOR': 3, 'VIT': 2}),

  // Conquistas de Vitalidade
  Achievement(
      id: 'ach_prancha_5min',
      description: "achPrancha5minDesc",
      linkedExerciseId: 'prancha_frontal',
      durationCondition: 5,
      expReward: 300,
      titleReward: "achPrancha5minTitle",
      statBonuses: {'VIT': 4}),
  Achievement(
      id: 'ach_prancha_10min',
      description: "achPrancha10minDesc",
      linkedExerciseId: 'prancha_frontal',
      durationCondition: 10,
      expReward: 600,
      titleReward: "achPrancha10minTitle",
      statBonuses: {'VIT': 8}),
  Achievement(
      id: 'ach_100_abdominais',
      description: "ach100AbdominaisDesc",
      linkedExerciseId: 'abdominal_supra_solo',
      repsCondition: 100,
      expReward: 250,
      titleReward: "ach100AbdominaisTitle",
      statBonuses: {'VIT': 3}),
  Achievement(
      id: 'ach_200_abdominais',
      description: "ach200AbdominaisDesc",
      linkedExerciseId: 'abdominal_supra_solo',
      repsCondition: 200,
      expReward: 500,
      titleReward: "ach200AbdominaisTitle",
      statBonuses: {'VIT': 6}),

  // Conquistas de Agilidade
  Achievement(
      id: 'ach_corrida_60min',
      description: "achCorrida60minDesc",
      linkedExerciseId: 'corrida_esteira',
      durationCondition: 60,
      expReward: 400,
      titleReward: "achCorrida60minTitle",
      statBonuses: {'AGI': 5, 'VIT': 2}),
  Achievement(
      id: 'ach_corrida_30min',
      description: "achCorrida30minDesc",
      linkedExerciseId: 'corrida_esteira',
      durationCondition: 30,
      expReward: 200,
      titleReward: "achCorrida30minTitle",
      statBonuses: {'AGI': 3}),
  Achievement(
      id: 'ach_bike_45min',
      description: "achBike45minDesc",
      linkedExerciseId: 'bicicleta_ergometrica',
      durationCondition: 45,
      expReward: 250,
      titleReward: "achBike45minTitle",
      statBonuses: {'AGI': 3, 'VIT': 2}),
  Achievement(
      id: 'ach_mountain_climber_300',
      description: "achMountainClimber300Desc",
      linkedExerciseId: 'mountain_climber',
      repsCondition: 300,
      expReward: 300,
      titleReward: "achMountainClimber300Title",
      statBonuses: {'AGI': 4}),

  // Conquistas de Inteligência (exercícios de coordenação e técnica)
  Achievement(
      id: 'ach_dead_bug_100',
      description: "achDeadBug100Desc",
      linkedExerciseId: 'dead_bug',
      repsCondition: 100,
      expReward: 200,
      titleReward: "achDeadBug100Title",
      statBonuses: {'INT': 3, 'VIT': 2}),
  Achievement(
      id: 'ach_bird_dog_10min',
      description: "achBirdDog10minDesc",
      linkedExerciseId: 'bird_dog',
      durationCondition: 10,
      expReward: 250,
      titleReward: "achBirdDog10minTitle",
      statBonuses: {'INT': 4}),
  Achievement(
      id: 'ach_russian_twist_200',
      description: "achRussianTwist200Desc",
      linkedExerciseId: 'russian_twist',
      repsCondition: 200,
      expReward: 300,
      titleReward: "achRussianTwist200Title",
      statBonuses: {'INT': 4, 'AGI': 2}),

  // Conquistas de Percepção (exercícios de equilíbrio e propriocepção)
  Achievement(
      id: 'ach_10_barras',
      description: "ach10BarrasDesc",
      linkedExerciseId: 'barra_fixa_pronada',
      repsCondition: 10,
      expReward: 350,
      titleReward: "ach10BarrasTitle",
      statBonuses: {'PER': 4, 'FOR': 3}),
  Achievement(
      id: 'ach_20_barras',
      description: "ach20BarrasDesc",
      linkedExerciseId: 'barra_fixa_pronada',
      repsCondition: 20,
      expReward: 700,
      titleReward: "ach20BarrasTitle",
      statBonuses: {'PER': 8, 'FOR': 5}),
  Achievement(
      id: 'ach_prancha_lateral_5min',
      description: "achPranchaLateral5minDesc",
      linkedExerciseId: 'prancha_lateral_direita',
      durationCondition: 5,
      expReward: 250,
      titleReward: "achPranchaLateral5minTitle",
      statBonuses: {'PER': 3, 'VIT': 2}),
  Achievement(
      id: 'ach_step_up_100',
      description: "achStepUp100Desc",
      linkedExerciseId: 'step_up',
      repsCondition: 100,
      expReward: 200,
      titleReward: "achStepUp100Title",
      statBonuses: {'PER': 3, 'AGI': 2}),

  // Conquistas Mistas (múltiplos atributos)
  Achievement(
      id: 'ach_burpees_50',
      description: "achBurpees50Desc",
      linkedExerciseId: 'burpees',
      repsCondition: 50,
      expReward: 400,
      titleReward: "achBurpees50Title",
      statBonuses: {'FOR': 2, 'VIT': 3, 'AGI': 3}),
  Achievement(
      id: 'ach_crossfit_combo',
      description: "achCrossfitComboDesc",
      linkedExerciseId: 'combo_crossfit',
      expReward: 1000,
      titleReward: "achCrossfitComboTitle",
      statBonuses: {'FOR': 5, 'VIT': 5, 'AGI': 5, 'PER': 3}),

  // Conquistas de Levantamento Pesado
  Achievement(
      id: 'ach_deadlift_200kg',
      description: "achDeadlift200kgDesc",
      linkedExerciseId: 'levantamento_terra',
      weightCondition: 200,
      repsCondition: 1,
      expReward: 800,
      titleReward: "achDeadlift200kgTitle",
      statBonuses: {'FOR': 8, 'VIT': 4}),
  Achievement(
      id: 'ach_leg_press_300kg',
      description: "achLegPress300kgDesc",
      linkedExerciseId: 'leg_press_45',
      weightCondition: 300,
      repsCondition: 1,
      expReward: 600,
      titleReward: "achLegPress300kgTitle",
      statBonuses: {'FOR': 6, 'VIT': 3}),
];

class ConquistasScreen extends StatefulWidget {
  const ConquistasScreen({super.key});

  @override
  State<ConquistasScreen> createState() => _ConquistasScreenState();
}

class _ConquistasScreenState extends State<ConquistasScreen> {
  List<Achievement> _userAchievementsToDisplay = []; // Lista para exibir na UI
  bool _isLoading = true;

  // Helper para tradução
  String _t(String key) {
    final languageService = context.read<LanguageService>();
    return TranslationService.get(key, languageService.currentLanguageCode);
  }

  @override
  void initState() {
    super.initState();
    _loadUserAchievementsStatus();
  }

  Future<void> _loadUserAchievementsStatus() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print(_t('noUserLoggedAchievements'));
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      Map<String, dynamic> completedAchievementsMapFirestore = {};
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('completedAchievements') &&
            data['completedAchievements'] is Map) {
          completedAchievementsMapFirestore =
              Map<String, dynamic>.from(data['completedAchievements']);
        }
      }

      List<Achievement> tempDisplayAchievements =
          allPossibleAchievements.map((masterAch) {
        return Achievement(
          // Cria uma nova instância para a UI
          id: masterAch.id,
          description: masterAch.description,
          expReward: masterAch.expReward,
          titleReward: masterAch.titleReward,
          linkedExerciseId: masterAch.linkedExerciseId,
          weightCondition: masterAch.weightCondition,
          repsCondition: masterAch.repsCondition,
          durationCondition: masterAch.durationCondition,
          isCompleted: completedAchievementsMapFirestore[masterAch.id] == true,
        );
      }).toList();

      tempDisplayAchievements.sort((a, b) =>
          a.isCompleted == b.isCompleted ? 0 : (a.isCompleted ? 1 : -1));

      if (mounted) {
        setState(() {
          _userAchievementsToDisplay = tempDisplayAchievements;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("${_t('achievementsLoadError')}: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // _completeAchievement foi removida daqui, pois o desbloqueio é automático na WorkoutExecutionScreen

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Scaffold(
          backgroundColor: primaryColor,
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: accentColorPurple))
              : _userAchievementsToDisplay.isEmpty && !_isLoading
                  ? Center(
                      child: Text(
                        _t('noAchievementsSystem'),
                        style: TextStyle(color: textColor, fontSize: 16),
                      ))
                  : RefreshIndicator(
                      // Permite "puxar para atualizar"
                      onRefresh: _loadUserAchievementsStatus,
                      color: accentColorPurple,
                      backgroundColor: primaryColor,
                      child: CustomScrollView(
                        slivers: [
                          SliverAppBar(
                            backgroundColor: primaryColor,
                            surfaceTintColor: primaryColor,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            automaticallyImplyLeading: false,
                            floating: false,
                            pinned: true,
                            title: Text(
                              _t('achievements').toUpperCase(),
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            centerTitle: true,
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.all(10.0),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final achievement =
                                      _userAchievementsToDisplay[index];
                                  return Card(
                                    color: achievement.isCompleted
                                        ? panelBgColor.withOpacity(0.5)
                                        : panelBgColor, // Diferencia cor se completada
                                    elevation: 2,
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8.0),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                        side: BorderSide(
                                            color: accentColorBlue.withOpacity(
                                                achievement.isCompleted
                                                    ? 0.3
                                                    : 0.6))),
                                    child: ListTile(
                                      // Usando ListTile para uma aparência mais limpa e sem checkbox interativo
                                      leading: Icon(
                                        // Ícone indicando status
                                        achievement.isCompleted
                                            ? Icons.check_circle_rounded
                                            : Icons.workspace_premium_outlined,
                                        color: achievement.isCompleted
                                            ? Colors.greenAccent
                                            : achievementColor,
                                        size: 30,
                                      ),
                                      title: Text(
                                        _t(achievement.description),
                                        style: TextStyle(
                                          color: achievement.isCompleted
                                              ? Colors.grey.shade400
                                              : textColor,
                                          fontSize: 16,
                                          decoration: achievement.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                          decorationColor: Colors.grey.shade600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        "${_t('reward')}: ${achievement.expReward} ${_t('experience')}${achievement.titleReward != null ? ", ${_t('title')}: '${_t(achievement.titleReward!)}'" : ""}",
                                        style: TextStyle(
                                            color: achievement.isCompleted
                                                ? Colors.grey.shade500
                                                : textColor.withOpacity(0.7),
                                            fontSize: 12),
                                      ),
                                      // Não há onChanged, pois não é mais interativo aqui
                                    ),
                                  );
                                },
                                childCount: _userAchievementsToDisplay.length,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
        );
      },
    );
  }
}
