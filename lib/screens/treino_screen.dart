// Em lib/screens/treino_screen.dart
// ignore_for_file: avoid_print, deprecated_member_use, unnecessary_brace_in_string_interps, prefer_const_constructors, use_build_context_synchronously

import 'dart:async';
import 'dart:math'; // Para pow
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:gym_leveling/services/settings_service.dart';
import 'package:gym_leveling/utils/dialog_utils.dart';
import 'package:gym_leveling/services/language_service.dart';
import 'package:gym_leveling/services/translation_service.dart';

// Cores
const Color primaryColor = Color(0xFF0A0E21);
const Color accentColorBlue = Color(0xFF40C4FF);
const Color accentColorPurple = Color(0xFF8A2BE2);
const Color textColor = Colors.white;
const Color panelBgColor = Color(0x991D1E33);
const Color prColor = Colors.amberAccent;
const Color levelUpColor = Colors.amberAccent;
const Color achievementColor = Colors.amberAccent;
const Color greenStatColor = Colors.greenAccent;

// --- MODELOS DE DADOS ---
class Exercise {
  final String id;
  final String name;
  final String bodyPart;
  final bool isTimeBased;
  final double? achievementWeight;
  final int? achievementReps;
  final int? achievementDuration;

  Exercise({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.isTimeBased,
    this.achievementWeight,
    this.achievementReps,
    this.achievementDuration,
  });

  // Factory para criar a partir do Firestore
  factory Exercise.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Exercise(
      id: doc.id,
      name: data['name'] ?? 'Nome Desconhecido',
      bodyPart: data['bodyPart'] ?? 'Desconhecido',
      isTimeBased: data['isTimeBased'] ?? false,
      achievementWeight: data['achievementWeight']?.toDouble(),
      achievementReps: data['achievementReps'],
      achievementDuration: data['achievementDuration'],
    );
  }

  // Factory para criar a partir de Map
  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] ?? 'unknown_id',
      name: map['name'] ?? 'Nome Desconhecido',
      bodyPart: map['bodyPart'] ?? 'Desconhecido',
      isTimeBased: map['isTimeBased'] ?? false,
      achievementWeight: map['achievementWeight']?.toDouble(),
      achievementReps: map['achievementReps'],
      achievementDuration: map['achievementDuration'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bodyPart': bodyPart,
      'isTimeBased': isTimeBased,
      'achievementWeight': achievementWeight,
      'achievementReps': achievementReps,
      'achievementDuration': achievementDuration,
    };
  }
}

class PlannedExercise {
  final Exercise exercise;
  final int sets;
  final int? reps;
  final int? durationMinutes;
  double? lastWeight;

  PlannedExercise({
    required this.exercise,
    required this.sets,
    this.reps,
    this.durationMinutes,
    this.lastWeight,
  });

  // Factory para criar a partir de Map (corrigido para ambos os formatos)
  factory PlannedExercise.fromMap(Map<String, dynamic> map) {
    try {
      print("Attempting to parse PlannedExercise map: $map");
      
      Exercise exercise;
      
      // Verificar qual formato estamos usando
      if (map.containsKey('exercise') && map['exercise'] != null) {
        // Formato 1: {exercise: {...}, sets: 3, ...}
        Map<String, dynamic> exerciseData = map['exercise'] as Map<String, dynamic>;
        String exerciseId = exerciseData['id']?.toString() ?? 'unknown_id';
        print("Exercise ID found (Format 1): $exerciseId");
        exercise = Exercise.fromMap(exerciseData);
      } else if (map.containsKey('exerciseId')) {
        // Formato 2: {exerciseId: "sup_r", exerciseName: "Supino", ...}
        String exerciseId = map['exerciseId']?.toString() ?? 'unknown_id';
        print("Exercise ID found (Format 2): $exerciseId");
        
        Map<String, dynamic> exerciseData = {
          'id': exerciseId,
          'name': map['exerciseName'] ?? 'Nome Desconhecido',
          'bodyPart': map['exerciseBodyPart'] ?? 'Desconhecido',
          'isTimeBased': map['isTimeBased'] ?? false,
          'achievementWeight': map['achievementWeight'],
          'achievementReps': map['achievementReps'],
          'achievementDuration': map['achievementDuration'],
        };
        exercise = Exercise.fromMap(exerciseData);
      } else {
        throw Exception("Formato de dados não reconhecido - nem 'exercise' nem 'exerciseId' encontrados");
      }
      
      return PlannedExercise(
        exercise: exercise,
        sets: map['sets'] ?? 1,
        reps: map['reps'],
        durationMinutes: map['durationMinutes'],
        lastWeight: map['lastWeight']?.toDouble(),
      );
    } catch (e) {
      print("Erro ao fazer parse do PlannedExercise: $e");
      print("Map problemático: $map");
      // Retornar um exercício padrão em caso de erro
      return PlannedExercise(
        exercise: Exercise(
          id: 'error_fallback',
          name: 'Exercício com Erro',
          bodyPart: 'Desconhecido',
          isTimeBased: false,
        ),
        sets: 1,
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'exercise': exercise.toMap(),
      'sets': sets,
      'reps': reps,
      'durationMinutes': durationMinutes,
      'lastWeight': lastWeight,
    };
  }
}

// Função para buscar exercício no Firestore (corrigida)
Future<Exercise?> getExerciseFromFirestore(String exerciseId) async {
  try {
    print("Looking up exerciseId: $exerciseId");
    
    if (exerciseId.isEmpty || exerciseId == 'null' || exerciseId == 'unknown_id') {
      print("Invalid exercise ID provided");
      return null;
    }

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('exercises')
        .doc(exerciseId)
        .get();

    if (doc.exists) {
      print("Found exercise in Firestore: ${doc.data()}");
      return Exercise.fromFirestore(doc);
    } else {
      print("Exercise not found in Firestore for ID: $exerciseId");
      return null;
    }
  } catch (e) {
    print("Erro ao buscar exercício no Firestore: $e");
    return null;
  }
}

// Função para criar PlannedExercise com busca no Firestore (corrigida para ambos os formatos)
Future<PlannedExercise> createPlannedExerciseWithFirestore(Map<String, dynamic> map) async {
  try {
    print("Attempting to parse PlannedExercise map: $map");
    
    Exercise? exercise;
    String exerciseId = '';
    
    // Verificar qual formato estamos usando e extrair o exerciseId
    if (map.containsKey('exercise') && map['exercise'] != null) {
      // Formato 1: {exercise: {...}, sets: 3, ...}
      Map<String, dynamic> exerciseData = map['exercise'] as Map<String, dynamic>;
      exerciseId = exerciseData['id']?.toString() ?? '';
      print("Looking up exerciseId (Format 1): $exerciseId");
      
      // Tentar buscar no Firestore primeiro
      if (exerciseId.isNotEmpty && exerciseId != 'null') {
        exercise = await getExerciseFromFirestore(exerciseId);
      }
      
      // Se não encontrou no Firestore, usar os dados locais
      if (exercise == null) {
        print("Using local data as fallback for exercise.");
        exercise = Exercise.fromMap(exerciseData);
      }
    } else if (map.containsKey('exerciseId')) {
      // Formato 2: {exerciseId: "sup_r", exerciseName: "Supino", ...}
      exerciseId = map['exerciseId']?.toString() ?? '';
      print("Looking up exerciseId (Format 2): $exerciseId");
      
      // Tentar buscar no Firestore primeiro
      if (exerciseId.isNotEmpty && exerciseId != 'null') {
        exercise = await getExerciseFromFirestore(exerciseId);
      }
      
      // Se não encontrou no Firestore, criar a partir dos dados locais
      if (exercise == null) {
        print("Using local data as fallback for exercise.");
        Map<String, dynamic> exerciseData = {
          'id': exerciseId,
          'name': map['exerciseName'] ?? 'Nome Desconhecido',
          'bodyPart': map['exerciseBodyPart'] ?? 'Desconhecido',
          'isTimeBased': map['isTimeBased'] ?? false,
          'achievementWeight': map['achievementWeight'],
          'achievementReps': map['achievementReps'],
          'achievementDuration': map['achievementDuration'],
        };
        exercise = Exercise.fromMap(exerciseData);
      }
    } else {
      throw Exception("Formato de dados não reconhecido - nem 'exercise' nem 'exerciseId' encontrados");
    }
    
    print("Created/Found exercise: ${exercise.name} (ID: ${exercise.id})");
      
    PlannedExercise plannedExercise = PlannedExercise(
      exercise: exercise,
      sets: map['sets'] ?? 1,
      reps: map['reps'],
      durationMinutes: map['durationMinutes'],
      lastWeight: map['lastWeight']?.toDouble(),
    );
    
    print("Parsed PlannedExercise: Exercise Name: ${plannedExercise.exercise.name}, Sets: ${plannedExercise.sets}, Reps: ${plannedExercise.reps}, Duration: ${plannedExercise.durationMinutes}");
    
    return plannedExercise;
  } catch (e) {
    print("Erro ao criar PlannedExercise: $e");
    print("Map problemático: $map");
    // Retornar exercício padrão em caso de erro
    return PlannedExercise(
      exercise: Exercise(
        id: 'error_fallback',
        name: 'Exercício com Erro',
        bodyPart: 'Desconhecido',
        isTimeBased: false,
      ),
      sets: 1,
    );
  }
}

// Função para salvar plano de treino no Firestore (melhorada)
Future<void> saveWorkoutPlanToFirestore(String day, List<PlannedExercise> exercises) async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    print("Usuário não autenticado");
    return;
  }

  try {
    // Converter exercícios para Map
    List<Map<String, dynamic>> exerciseMaps = exercises.map((e) => e.toMap()).toList();
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('workoutPlans')
        .doc(day)
        .set({
      'exercises': exerciseMaps,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    
    print("Plano de treino salvo com sucesso para o dia: $day");
  } catch (e) {
    print("Erro ao salvar plano de treino: $e");
    rethrow; // Re-lançar o erro para que possa ser tratado na UI
  }
}

// Função para carregar plano de treino do Firestore
Future<List<PlannedExercise>> loadWorkoutPlanFromFirestore(String day) async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    print("Usuário não autenticado");
    return [];
  }

  try {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('workoutPlans')
        .doc(day)
        .get();

    if (!doc.exists) {
      print("Nenhum plano de treino encontrado para o dia: $day");
      return [];
    }

    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    List<dynamic> exercisesData = data['exercises'] ?? [];

    List<PlannedExercise> exercises = [];
    
    for (var exerciseMap in exercisesData) {
      PlannedExercise plannedExercise = await createPlannedExerciseWithFirestore(exerciseMap);
      exercises.add(plannedExercise);
    }

    print("Carregados ${exercises.length} exercícios para o dia: $day");
    return exercises;
  } catch (e) {
    print("Erro ao carregar plano de treino: $e");
    return [];
  }
}

class Achievement {
  final String id;
  final String description;
  final int expReward;
  final String? titleReward;
  final String linkedExerciseId;
  final double? weightCondition;
  final int? repsCondition;
  final int? durationCondition; // Em minutos
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

// Lista completa de exercícios
final List<Exercise> allMasterExercisesList = [
  // Exercícios de Peito
  Exercise(id: 'sup_r', name: 'Supino Reto Barra', bodyPart: 'Peito', isTimeBased: false, achievementWeight: 100, achievementReps: 1),
  Exercise(id: 'supino_reto_halteres', name: 'Supino Reto com Halteres', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'supino_inclinado_barra', name: 'Supino Inclinado Barra', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'supino_inclinado_halteres', name: 'Supino Inclinado Halteres', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'supino_inclinado_maquina', name: 'Supino Inclinado Máquina', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'supino_declinado_barra', name: 'Supino Declinado Barra', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'supino_declinado_halteres', name: 'Supino Declinado Halteres', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'supino_declinado_maquina', name: 'Supino Declinado Máquina', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'supino_smith', name: 'Supino no Smith Machine', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'crucifixo_reto_halteres', name: 'Crucifixo Reto Halteres', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'crucifixo_reto_cabo', name: 'Crucifixo Reto Cabo', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'crucifixo_inclinado_halteres', name: 'Crucifixo Inclinado Halteres', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'crucifixo_inclinado_cabo', name: 'Crucifixo Inclinado Cabo', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'crucifixo_declinado_halteres', name: 'Crucifixo Declinado Halteres', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'cross_over_alto', name: 'Cross Over Alto', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'cross_over_baixo', name: 'Cross Over Baixo', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'cross_over_meio', name: 'Cross Over Meio', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'paralelas_peito', name: 'Paralelas (Foco Peito)', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'flexao_tradicional', name: 'Flexão de Braço Tradicional', bodyPart: 'Peito', isTimeBased: false, achievementReps: 50),
  Exercise(id: 'flexao_fechada', name: 'Flexão de Braço Fechada', bodyPart: 'Tríceps/Peito', isTimeBased: false),
  Exercise(id: 'flexao_maos_afastadas', name: 'Flexão de Mãos Afastadas', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'flexao_declinada', name: 'Flexão Declinada com Suporte', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'flexao_inclinada', name: 'Flexão Inclinada', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'flexao_diamante', name: 'Flexão Diamante', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'voador_peck_deck', name: 'Voador (Peck Deck)', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'voador_maquina', name: 'Voador Máquina', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'pullover_halter', name: 'Pullover com Halter', bodyPart: 'Costas/Peito', isTimeBased: false),
  Exercise(id: 'pullover_cabo', name: 'Pullover com Cabo', bodyPart: 'Costas/Peito', isTimeBased: false),
  Exercise(id: 'supino_neutro_halteres', name: 'Supino Neutro com Halteres', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'chest_press', name: 'Chest Press Máquina', bodyPart: 'Peito', isTimeBased: false),

  // Exercícios de Costas
  Exercise(id: 'barra_fixa_pronada', name: 'Barra Fixa Pegada Pronada', bodyPart: 'Costas', isTimeBased: false, achievementReps: 10),
  Exercise(id: 'barra_fixa_supinada', name: 'Barra Fixa Pegada Supinada', bodyPart: 'Costas/Bíceps', isTimeBased: false),
  Exercise(id: 'barra_fixa_neutra', name: 'Barra Fixa Pegada Neutra', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'barra_fixa_aberta', name: 'Barra Fixa Pegada Aberta', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'puxada_frente_pronada', name: 'Puxada Frente Pegada Pronada', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'puxada_frente_supinada', name: 'Puxada Frente Pegada Supinada', bodyPart: 'Costas/Bíceps', isTimeBased: false),
  Exercise(id: 'puxada_frente_neutra', name: 'Puxada Frente Pegada Neutra', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'puxada_tras_nuca', name: 'Puxada Atrás da Nuca', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'puxada_unilateral', name: 'Puxada Unilateral', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'remada_curvada_pronada', name: 'Remada Curvada Barra Pegada Pronada', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'remada_curvada_supinada', name: 'Remada Curvada Barra Pegada Supinada', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'remada_curvada_halteres', name: 'Remada Curvada com Halteres', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'remada_sentada_neutra', name: 'Remada Sentada Pegada Neutra', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'remada_sentada_pronada', name: 'Remada Sentada Pegada Pronada', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'remada_sentada_supinada', name: 'Remada Sentada Pegada Supinada', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'remada_cavalinho_pronada', name: 'Remada Cavalinho Pegada Pronada', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'remada_cavalinho_triangulo', name: 'Remada Cavalinho Triângulo', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'remada_cavalinho_neutra', name: 'Remada Cavalinho Pegada Neutra', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'serrote_halter', name: 'Remada Unilateral Halter (Serrote)', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'remada_unilateral_maquina', name: 'Remada Unilateral Máquina', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'remada_unilateral_cabo', name: 'Remada Unilateral Cabo', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'remada_baixa_cabo', name: 'Remada Baixa Cabo', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'remada_alta_cabo', name: 'Remada Alta Cabo', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'levantamento_terra_convencional', name: 'Levantamento Terra Convencional', bodyPart: 'Posterior de Coxa/Costas/Glúteos', isTimeBased: false),
  Exercise(id: 'levantamento_terra_sumo', name: 'Levantamento Terra Sumo', bodyPart: 'Posterior de Coxa/Costas/Glúteos', isTimeBased: false),
  Exercise(id: 'levantamento_terra_romeno', name: 'Levantamento Terra Romeno', bodyPart: 'Posterior de Coxa/Costas/Glúteos', isTimeBased: false),
  Exercise(id: 'levantamento_terra_trap_bar', name: 'Levantamento Terra Trap Bar', bodyPart: 'Posterior de Coxa/Costas/Glúteos', isTimeBased: false),
  Exercise(id: 'face_pull', name: 'Face Pull', bodyPart: 'Ombros (Posterior)/Costas', isTimeBased: false),
  Exercise(id: 'puxada_alta_triangulo', name: 'Puxada Alta Triângulo', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'hiperextensao_lombar', name: 'Hiperextensão Lombar', bodyPart: 'Lombar', isTimeBased: false),
  Exercise(id: 'good_morning', name: 'Good Morning', bodyPart: 'Lombar', isTimeBased: false),
  Exercise(id: 'remada_t_bar', name: 'Remada T-Bar', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'remada_landmine', name: 'Remada Landmine', bodyPart: 'Costas', isTimeBased: false),

  // Exercícios de Ombros
  Exercise(id: 'desenvolvimento_militar_pe', name: 'Desenvolvimento Militar em Pé', bodyPart: 'Ombros', isTimeBased: false),
  Exercise(id: 'desenvolvimento_militar_sentado', name: 'Desenvolvimento Militar Sentado', bodyPart: 'Ombros', isTimeBased: false),
  Exercise(id: 'desenvolvimento_halteres_sentado', name: 'Desenvolvimento Halteres Sentado', bodyPart: 'Ombros', isTimeBased: false),
  Exercise(id: 'desenvolvimento_halteres_pe', name: 'Desenvolvimento Halteres em Pé', bodyPart: 'Ombros', isTimeBased: false),
  Exercise(id: 'desenvolvimento_maquina', name: 'Desenvolvimento Máquina', bodyPart: 'Ombros', isTimeBased: false),
  Exercise(id: 'desenvolvimento_smith', name: 'Desenvolvimento no Smith', bodyPart: 'Ombros', isTimeBased: false),
  Exercise(id: 'desenvolvimento_arnold', name: 'Desenvolvimento Arnold', bodyPart: 'Ombros', isTimeBased: false),
  Exercise(id: 'elevacao_lateral_halteres', name: 'Elevação Lateral Halteres', bodyPart: 'Ombros', isTimeBased: false),
  Exercise(id: 'elevacao_lateral_cabo', name: 'Elevação Lateral Cabo', bodyPart: 'Ombros', isTimeBased: false),
  Exercise(id: 'elevacao_lateral_maquina', name: 'Elevação Lateral Máquina', bodyPart: 'Ombros', isTimeBased: false),
  Exercise(id: 'elevacao_lateral_unilateral', name: 'Elevação Lateral Unilateral', bodyPart: 'Ombros', isTimeBased: false),
  Exercise(id: 'elevacao_frontal_barra', name: 'Elevação Frontal Barra', bodyPart: 'Ombros', isTimeBased: false),
  Exercise(id: 'elevacao_frontal_halteres', name: 'Elevação Frontal Halteres', bodyPart: 'Ombros', isTimeBased: false),
  Exercise(id: 'elevacao_frontal_cabo', name: 'Elevação Frontal Cabo', bodyPart: 'Ombros', isTimeBased: false),
  Exercise(id: 'elevacao_frontal_anilha', name: 'Elevação Frontal Anilha', bodyPart: 'Ombros', isTimeBased: false),
  Exercise(id: 'crucifixo_invertido_halteres', name: 'Crucifixo Invertido Halteres', bodyPart: 'Ombros (Posterior)/Costas', isTimeBased: false),
  Exercise(id: 'crucifixo_invertido_cabo', name: 'Crucifixo Invertido Cabo', bodyPart: 'Ombros (Posterior)/Costas', isTimeBased: false),
  Exercise(id: 'crucifixo_invertido_maquina', name: 'Crucifixo Invertido Máquina', bodyPart: 'Ombros (Posterior)/Costas', isTimeBased: false),
  Exercise(id: 'remada_alta_barra', name: 'Remada Alta Barra', bodyPart: 'Ombros/Trapézio', isTimeBased: false),
  Exercise(id: 'remada_alta_cabo', name: 'Remada Alta Cabo', bodyPart: 'Ombros/Trapézio', isTimeBased: false),
  Exercise(id: 'remada_alta_halteres', name: 'Remada Alta Halteres', bodyPart: 'Ombros/Trapézio', isTimeBased: false),
  Exercise(id: 'encolhimento_barra', name: 'Encolhimento Ombros Barra', bodyPart: 'Ombros/Trapézio', isTimeBased: false),
  Exercise(id: 'encolhimento_halteres', name: 'Encolhimento Ombros Halteres', bodyPart: 'Ombros/Trapézio', isTimeBased: false),
  Exercise(id: 'encolhimento_smith', name: 'Encolhimento no Smith', bodyPart: 'Ombros/Trapézio', isTimeBased: false),
  Exercise(id: 'voador_invertido', name: 'Voador Invertido', bodyPart: 'Ombros (Posterior)/Costas', isTimeBased: false),
  Exercise(id: 'elevacao_posterior_cabo', name: 'Elevação Posterior Cabo', bodyPart: 'Ombros (Posterior)/Costas', isTimeBased: false),

  // Exercícios de Pernas
  Exercise(id: 'agachamento_livre', name: 'Agachamento Livre', bodyPart: 'Pernas', isTimeBased: false, achievementWeight: 150, achievementReps: 1),
  Exercise(id: 'agachamento_frontal', name: 'Agachamento Frontal', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'agachamento_hack', name: 'Agachamento Hack', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'agachamento_smith', name: 'Agachamento Smith', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'agachamento_sumo', name: 'Agachamento Sumo', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'agachamento_bulgaro', name: 'Agachamento Búlgaro', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'agachamento_goblet', name: 'Agachamento Goblet', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'leg_press_45', name: 'Leg Press 45°', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'leg_press_horizontal', name: 'Leg Press Horizontal', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'leg_press_vertical', name: 'Leg Press Vertical', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'leg_press_unilateral', name: 'Leg Press Unilateral', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'cadeira_extensora', name: 'Cadeira Extensora', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'extensora_unilateral', name: 'Extensora Unilateral', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'mesa_flexora', name: 'Mesa Flexora', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'mesa_flexora_unilateral', name: 'Mesa Flexora Unilateral', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'cadeira_flexora', name: 'Cadeira Flexora', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'flexora_em_pe', name: 'Flexora em Pé', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'stiff_barra', name: 'Stiff com Barra', bodyPart: 'Posterior de Coxa/Costas/Glúteos', isTimeBased: false),
  Exercise(id: 'stiff_halteres', name: 'Stiff com Halteres', bodyPart: 'Posterior de Coxa/Costas/Glúteos', isTimeBased: false),
  Exercise(id: 'afundo_halteres', name: 'Afundo com Halteres', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'afundo_barra', name: 'Afundo com Barra', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'afundo_reverso', name: 'Afundo Reverso', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'afundo_lateral', name: 'Afundo Lateral', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'afundo_caminhada', name: 'Afundo Caminhada', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'passada_larga', name: 'Passada Larga', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'step_up', name: 'Step Up', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'adutora_maquina', name: 'Adutora Máquina', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'abdutora_maquina', name: 'Abdutora Máquina', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'elevacao_quadril', name: 'Elevação de Quadril', bodyPart: 'Posterior de Coxa/Costas/Glúteos', isTimeBased: false),
  Exercise(id: 'ponte_glutea', name: 'Ponte Glútea', bodyPart: 'Posterior de Coxa/Costas/Glúteos', isTimeBased: false),
  Exercise(id: 'coice_maquina', name: 'Coice na Máquina', bodyPart: 'Posterior de Coxa/Costas/Glúteos', isTimeBased: false),
  Exercise(id: 'coice_cabo', name: 'Coice no Cabo', bodyPart: 'Posterior de Coxa/Costas/Glúteos', isTimeBased: false),

  // Exercícios de Panturrilha
  Exercise(id: 'panturrilha_sentado', name: 'Panturrilha Sentado', bodyPart: 'Panturrilha', isTimeBased: false),
  Exercise(id: 'panturrilha_em_pe', name: 'Panturrilha em Pé', bodyPart: 'Panturrilha', isTimeBased: false),
  Exercise(id: 'panturrilha_smith', name: 'Panturrilha no Smith', bodyPart: 'Panturrilha', isTimeBased: false),
  Exercise(id: 'panturrilha_leg_press', name: 'Panturrilha no Leg Press', bodyPart: 'Panturrilha', isTimeBased: false),
  Exercise(id: 'panturrilha_unilateral', name: 'Panturrilha Unilateral', bodyPart: 'Panturrilha', isTimeBased: false),
  Exercise(id: 'panturrilha_halteres', name: 'Panturrilha com Halteres', bodyPart: 'Panturrilha', isTimeBased: false),
  Exercise(id: 'panturrilha_45_graus', name: 'Panturrilha 45 Graus', bodyPart: 'Panturrilha', isTimeBased: false),

  // Exercícios de Bíceps
  Exercise(id: 'rosca_direta_barra', name: 'Rosca Direta Barra', bodyPart: 'Bíceps', isTimeBased: false),
  Exercise(id: 'rosca_direta_barra_w', name: 'Rosca Direta Barra W', bodyPart: 'Bíceps', isTimeBased: false),
  Exercise(id: 'rosca_alternada_halteres', name: 'Rosca Alternada Halteres', bodyPart: 'Bíceps', isTimeBased: false),
  Exercise(id: 'rosca_simultanea_halteres', name: 'Rosca Simultânea Halteres', bodyPart: 'Bíceps', isTimeBased: false),
  Exercise(id: 'rosca_scott_barra', name: 'Rosca Scott Barra', bodyPart: 'Bíceps', isTimeBased: false),
  Exercise(id: 'rosca_scott_halteres', name: 'Rosca Scott Halteres', bodyPart: 'Bíceps', isTimeBased: false),
  Exercise(id: 'rosca_scott_maquina', name: 'Rosca Scott Máquina', bodyPart: 'Bíceps', isTimeBased: false),
  Exercise(id: 'rosca_concentrada_halter', name: 'Rosca Concentrada Halter', bodyPart: 'Bíceps', isTimeBased: false),
  Exercise(id: 'rosca_concentrada_cabo', name: 'Rosca Concentrada Cabo', bodyPart: 'Bíceps', isTimeBased: false),
  Exercise(id: 'rosca_martelo_halteres', name: 'Rosca Martelo Halteres', bodyPart: 'Bíceps', isTimeBased: false),
  Exercise(id: 'rosca_martelo_cabo', name: 'Rosca Martelo Cabo', bodyPart: 'Bíceps', isTimeBased: false),
  Exercise(id: 'rosca_martelo_corda', name: 'Rosca Martelo Corda', bodyPart: 'Bíceps', isTimeBased: false),
  Exercise(id: 'rosca_cabo_baixo', name: 'Rosca Cabo Baixo', bodyPart: 'Bíceps', isTimeBased: false),
  Exercise(id: 'rosca_cabo_alto', name: 'Rosca Cabo Alto', bodyPart: 'Bíceps', isTimeBased: false),
  Exercise(id: 'rosca_21', name: 'Rosca 21', bodyPart: 'Bíceps', isTimeBased: false),
  Exercise(id: 'rosca_inversa_barra', name: 'Rosca Inversa Barra', bodyPart: 'Bíceps', isTimeBased: false),
  Exercise(id: 'rosca_punho_barra', name: 'Rosca Punho Barra', bodyPart: 'Bíceps', isTimeBased: false),
  Exercise(id: 'rosca_punho_halteres', name: 'Rosca Punho Halteres', bodyPart: 'Bíceps', isTimeBased: false),

  // Exercícios de Tríceps
  Exercise(id: 'triceps_pulley_barra', name: 'Tríceps Pulley Barra', bodyPart: 'Tríceps', isTimeBased: false),
  Exercise(id: 'triceps_pulley_corda', name: 'Tríceps Pulley Corda', bodyPart: 'Tríceps', isTimeBased: false),
  Exercise(id: 'triceps_pulley_barra_v', name: 'Tríceps Pulley Barra V', bodyPart: 'Tríceps', isTimeBased: false),
  Exercise(id: 'triceps_pulley_unilateral', name: 'Tríceps Pulley Unilateral', bodyPart: 'Tríceps', isTimeBased: false),
  Exercise(id: 'triceps_testa_barra', name: 'Tríceps Testa Barra', bodyPart: 'Tríceps', isTimeBased: false),
  Exercise(id: 'triceps_testa_barra_w', name: 'Tríceps Testa Barra W', bodyPart: 'Tríceps', isTimeBased: false),
  Exercise(id: 'triceps_testa_halteres', name: 'Tríceps Testa Halteres', bodyPart: 'Tríceps', isTimeBased: false),
  Exercise(id: 'triceps_frances_barra', name: 'Tríceps Francês Barra', bodyPart: 'Tríceps', isTimeBased: false),
  Exercise(id: 'triceps_frances_halter', name: 'Tríceps Francês Halter', bodyPart: 'Tríceps', isTimeBased: false),
  Exercise(id: 'triceps_frances_cabo', name: 'Tríceps Francês Cabo', bodyPart: 'Tríceps', isTimeBased: false),
  Exercise(id: 'triceps_coice_halteres', name: 'Tríceps Coice Halteres', bodyPart: 'Tríceps', isTimeBased: false),
  Exercise(id: 'triceps_coice_cabo', name: 'Tríceps Coice Cabo', bodyPart: 'Tríceps', isTimeBased: false),
  Exercise(id: 'triceps_mergulho_banco', name: 'Tríceps Mergulho Banco', bodyPart: 'Tríceps', isTimeBased: false),
  Exercise(id: 'triceps_mergulho_paralela', name: 'Tríceps Mergulho Paralela', bodyPart: 'Tríceps', isTimeBased: false),
  Exercise(id: 'triceps_supino_fechado', name: 'Tríceps Supino Fechado', bodyPart: 'Tríceps', isTimeBased: false),
  Exercise(id: 'triceps_maquina', name: 'Tríceps Máquina', bodyPart: 'Tríceps', isTimeBased: false),
  Exercise(id: 'triceps_banco_neutro', name: 'Tríceps Banco Neutro', bodyPart: 'Tríceps', isTimeBased: false),
  Exercise(id: 'triceps_diamond_pushup', name: 'Flexão Diamante (Tríceps)', bodyPart: 'Tríceps', isTimeBased: false),

  // Exercícios de Abdômen
  Exercise(id: 'abdominal_supra_solo', name: 'Abdominal Supra Solo', bodyPart: 'Abdômen', isTimeBased: false, achievementReps: 100),
  Exercise(id: 'abdominal_supra_declinado', name: 'Abdominal Supra Declinado', bodyPart: 'Abdômen', isTimeBased: false),
  Exercise(id: 'abdominal_infra_solo', name: 'Abdominal Infra Solo', bodyPart: 'Abdômen', isTimeBased: false),
  Exercise(id: 'abdominal_infra_paralela', name: 'Abdominal Infra Paralela', bodyPart: 'Abdômen', isTimeBased: false),
  Exercise(id: 'elevacao_pernas_capitao', name: 'Elevação de Pernas Capitão', bodyPart: 'Abdômen', isTimeBased: false),
  Exercise(id: 'elevacao_pernas_solo', name: 'Elevação de Pernas Solo', bodyPart: 'Abdômen', isTimeBased: false),
  Exercise(id: 'elevacao_joelhos_paralela', name: 'Elevação de Joelhos Paralela', bodyPart: 'Abdômen', isTimeBased: false),
  Exercise(id: 'abdominal_bicicleta', name: 'Abdominal Bicicleta', bodyPart: 'Abdômen', isTimeBased: false),
  Exercise(id: 'abdominal_remador', name: 'Abdominal Remador', bodyPart: 'Abdômen', isTimeBased: false),
  Exercise(id: 'abdominal_obliquo_solo', name: 'Abdominal Oblíquo Solo', bodyPart: 'Abdômen', isTimeBased: false),
  Exercise(id: 'abdominal_obliquo_cabo', name: 'Abdominal Oblíquo Cabo', bodyPart: 'Abdômen', isTimeBased: false),
  Exercise(id: 'abdominal_cable_crunch', name: 'Abdominal Cable Crunch', bodyPart: 'Abdômen', isTimeBased: false),
  Exercise(id: 'abdominal_maquina', name: 'Abdominal Máquina', bodyPart: 'Abdômen', isTimeBased: false),
  Exercise(id: 'prancha_frontal', name: 'Prancha Frontal', bodyPart: 'Abdômen', isTimeBased: true, achievementDuration: 5),
  Exercise(id: 'prancha_lateral_direita', name: 'Prancha Lateral Direita', bodyPart: 'Abdômen', isTimeBased: true),
  Exercise(id: 'prancha_lateral_esquerda', name: 'Prancha Lateral Esquerda', bodyPart: 'Abdômen', isTimeBased: true),
  Exercise(id: 'prancha_com_elevacao', name: 'Prancha com Elevação', bodyPart: 'Abdômen', isTimeBased: true),
  Exercise(id: 'mountain_climber', name: 'Mountain Climber', bodyPart: 'Abdômen', isTimeBased: true),
  Exercise(id: 'russian_twist', name: 'Russian Twist', bodyPart: 'Abdômen', isTimeBased: false),
  Exercise(id: 'dead_bug', name: 'Dead Bug', bodyPart: 'Abdômen', isTimeBased: false),
  Exercise(id: 'hollow_hold', name: 'Hollow Hold', bodyPart: 'Abdômen', isTimeBased: true),
  Exercise(id: 'v_ups', name: 'V-Ups', bodyPart: 'Abdômen', isTimeBased: false),
  Exercise(id: 'sit_ups', name: 'Sit-Ups', bodyPart: 'Abdômen', isTimeBased: false),
  Exercise(id: 'crunch_inverso', name: 'Crunch Inverso', bodyPart: 'Abdômen', isTimeBased: false),

  // Exercícios de Lombar
  Exercise(id: 'hiperextensao_lombar_45', name: 'Hiperextensão Lombar 45°', bodyPart: 'Lombar', isTimeBased: false),
  Exercise(id: 'hiperextensao_lombar_horizontal', name: 'Hiperextensão Lombar Horizontal', bodyPart: 'Lombar', isTimeBased: false),
  Exercise(id: 'extensao_lombar_solo', name: 'Extensão Lombar Solo (Superman)', bodyPart: 'Lombar', isTimeBased: false),
  Exercise(id: 'good_morning_barra', name: 'Good Morning com Barra', bodyPart: 'Lombar', isTimeBased: false),
  Exercise(id: 'good_morning_halteres', name: 'Good Morning com Halteres', bodyPart: 'Lombar', isTimeBased: false),
  Exercise(id: 'extensao_lombar_maquina', name: 'Extensão Lombar Máquina', bodyPart: 'Lombar', isTimeBased: false),
  Exercise(id: 'bird_dog', name: 'Bird Dog', bodyPart: 'Lombar', isTimeBased: true),
  Exercise(id: 'ponte_glutea_isometrica', name: 'Ponte Glútea Isométrica', bodyPart: 'Lombar', isTimeBased: true),

  // Exercícios de Cardio
  Exercise(id: 'corrida_esteira', name: 'Corrida Esteira', bodyPart: 'Cardio', isTimeBased: true, achievementDuration: 60),
  Exercise(id: 'caminhada_esteira', name: 'Caminhada Esteira', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'esteira_inclinada', name: 'Esteira Inclinada', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'corrida_intervalada', name: 'Corrida Intervalada', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'bicicleta_ergometrica', name: 'Bicicleta Ergométrica', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'bike_spinning', name: 'Bike Spinning', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'bike_reclinada', name: 'Bike Reclinada', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'eliptico', name: 'Elíptico', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'transport_eliptico', name: 'Transport (Elíptico)', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'escada_ergometrica', name: 'Escada Ergométrica', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'remo_ergometro', name: 'Remo Ergômetro', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'natacao_livre', name: 'Natação Livre', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'natacao_costas', name: 'Natação de Costas', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'natacao_peito', name: 'Natação de Peito', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'natacao_borboleta', name: 'Natação Borboleta', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'aqua_aerobica', name: 'Aqua Aeróbica', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'hidroginastica', name: 'Hidroginástica', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'corda_naval', name: 'Corda Naval (Battle Rope)', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'boxe_saco', name: 'Boxe no Saco de Pancadas', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'muay_thai_saco', name: 'Muay Thai no Saco', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'jump_rope', name: 'Pular Corda', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'burpees', name: 'Burpees', bodyPart: 'Cardio', isTimeBased: false),
  Exercise(id: 'jumping_jacks', name: 'Jumping Jacks', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'high_knees', name: 'High Knees', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'butt_kicks', name: 'Butt Kicks', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'box_jumps', name: 'Box Jumps', bodyPart: 'Cardio', isTimeBased: false),
  Exercise(id: 'step_ups_cardio', name: 'Step Ups Cardio', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'kettlebell_swing', name: 'Kettlebell Swing', bodyPart: 'Cardio', isTimeBased: false),
  Exercise(id: 'battle_rope_waves', name: 'Battle Rope Waves', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'circuit_training', name: 'Circuito Funcional', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'hiit_treino', name: 'HIIT (Treino Intervalado)', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'crossfit_wod', name: 'CrossFit WOD', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'tabata', name: 'Tabata', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'aerobica_step', name: 'Aeróbica com Step', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'zumba', name: 'Zumba', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'spinning_class', name: 'Aula de Spinning', bodyPart: 'Cardio', isTimeBased: true),

  // Exercícios Funcionais e Mistos
  Exercise(id: 'farmer_walk', name: 'Farmer Walk', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'turkish_get_up', name: 'Turkish Get Up', bodyPart: 'Cardio', isTimeBased: false),
  Exercise(id: 'clean_and_press', name: 'Clean and Press', bodyPart: 'Ombros', isTimeBased: false),
  Exercise(id: 'thruster', name: 'Thruster', bodyPart: 'Ombros', isTimeBased: false),
  Exercise(id: 'wall_ball', name: 'Wall Ball', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'slam_ball', name: 'Slam Ball', bodyPart: 'Cardio', isTimeBased: false),
  Exercise(id: 'tire_flip', name: 'Tire Flip', bodyPart: 'Cardio', isTimeBased: false),
  Exercise(id: 'sledgehammer', name: 'Sledgehammer', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'rope_climb', name: 'Subida na Corda', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'bear_crawl', name: 'Bear Crawl', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'crab_walk', name: 'Crab Walk', bodyPart: 'Cardio', isTimeBased: true),
  Exercise(id: 'duck_walk', name: 'Duck Walk', bodyPart: 'Pernas', isTimeBased: true),
  Exercise(id: 'plank_to_pushup', name: 'Prancha para Flexão', bodyPart: 'Abdômen', isTimeBased: false),
  Exercise(id: 'renegade_rows', name: 'Renegade Rows', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'man_makers', name: 'Man Makers', bodyPart: 'Cardio', isTimeBased: false),
  Exercise(id: 'devil_press', name: 'Devil Press', bodyPart: 'Cardio', isTimeBased: false),

  // Exercícios com Kettlebell
  Exercise(id: 'kettlebell_deadlift', name: 'Kettlebell Deadlift', bodyPart: 'Posterior de Coxa/Costas/Glúteos', isTimeBased: false),
  Exercise(id: 'kettlebell_goblet_squat', name: 'Kettlebell Goblet Squat', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'kettlebell_press', name: 'Kettlebell Press', bodyPart: 'Ombros', isTimeBased: false),
  Exercise(id: 'kettlebell_clean', name: 'Kettlebell Clean', bodyPart: 'Ombros', isTimeBased: false),
  Exercise(id: 'kettlebell_snatch', name: 'Kettlebell Snatch', bodyPart: 'Ombros', isTimeBased: false),
  Exercise(id: 'kettlebell_windmill', name: 'Kettlebell Windmill', bodyPart: 'Abdômen', isTimeBased: false),
  Exercise(id: 'kettlebell_halo', name: 'Kettlebell Halo', bodyPart: 'Ombros', isTimeBased: false),
  Exercise(id: 'kettlebell_figure_8', name: 'Kettlebell Figure 8', bodyPart: 'Cardio', isTimeBased: true),

  // Exercícios com TRX/Suspensão
  Exercise(id: 'trx_pushup', name: 'TRX Push-up', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'trx_row', name: 'TRX Row', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'trx_squat', name: 'TRX Squat', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'trx_lunge', name: 'TRX Lunge', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'trx_pike', name: 'TRX Pike', bodyPart: 'Abdômen', isTimeBased: false),
  Exercise(id: 'trx_mountain_climber', name: 'TRX Mountain Climber', bodyPart: 'Abdômen', isTimeBased: true),
  Exercise(id: 'trx_tricep_press', name: 'TRX Tricep Press', bodyPart: 'Tríceps', isTimeBased: false),
  Exercise(id: 'trx_bicep_curl', name: 'TRX Bicep Curl', bodyPart: 'Bíceps', isTimeBased: false),
  Exercise(id: 'trx_face_pull', name: 'TRX Face Pull', bodyPart: 'Ombros (Posterior)/Costas', isTimeBased: false),
  Exercise(id: 'trx_y_fly', name: 'TRX Y Fly', bodyPart: 'Ombros (Posterior)/Costas', isTimeBased: false),

  // Exercícios com Elástico/Faixa
  Exercise(id: 'elastico_peito', name: 'Elástico Peito', bodyPart: 'Peito', isTimeBased: false),
  Exercise(id: 'elastico_costas', name: 'Elástico Costas', bodyPart: 'Costas', isTimeBased: false),
  Exercise(id: 'elastico_ombros', name: 'Elástico Ombros', bodyPart: 'Ombros', isTimeBased: false),
  Exercise(id: 'elastico_biceps', name: 'Elástico Bíceps', bodyPart: 'Bíceps', isTimeBased: false),
  Exercise(id: 'elastico_triceps', name: 'Elástico Tríceps', bodyPart: 'Tríceps', isTimeBased: false),
  Exercise(id: 'elastico_pernas', name: 'Elástico Pernas', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'mini_band_walk', name: 'Mini Band Walk', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'monster_walk', name: 'Monster Walk', bodyPart: 'Pernas', isTimeBased: false),
  Exercise(id: 'clam_shell', name: 'Clam Shell', bodyPart: 'Posterior de Coxa/Costas/Glúteos', isTimeBased: false),
];

final List<Achievement> allPossibleAchievements = [
  // Conquistas de Força
  Achievement(id: 'ach_supino_100kg', description: "Levantou 100kg no Supino Reto com Barra (1 rep)", linkedExerciseId: 'sup_r', weightCondition: 100, repsCondition: 1, expReward: 500, titleReward: "Aquele que Levantou o Mundo", statBonuses: {'FOR': 5}),
  Achievement(id: 'ach_supino_50kg', description: "Levantou 50kg no Supino Reto com Barra (1 rep)", linkedExerciseId: 'sup_r', weightCondition: 50, repsCondition: 1, expReward: 200, titleReward: "Força Ascendente", statBonuses: {'FOR': 2}),
  Achievement(id: 'ach_agachamento_150kg', description: "Realizou Agachamento Livre com 150kg (1 rep)", linkedExerciseId: 'agachamento_livre', weightCondition: 150, repsCondition: 1, expReward: 750, titleReward: "Pernas de Aço", statBonuses: {'FOR': 5, 'VIT': 3}),
  Achievement(id: 'ach_agachamento_80kg', description: "Realizou Agachamento Livre com 80kg (1 rep)", linkedExerciseId: 'agachamento_livre', weightCondition: 80, repsCondition: 1, expReward: 300, titleReward: "Força nas Pernas", statBonuses: {'FOR': 3}),
  Achievement(id: 'ach_50_flexoes', description: "Realizou 50 Flexões de Braço Tradicionais em uma única sessão", linkedExerciseId: 'flexao_tradicional', repsCondition: 50, expReward: 200, titleReward: "Peito de Aço", statBonuses: {'FOR': 3, 'VIT': 2}),

  // Conquistas de Vitalidade
  Achievement(id: 'ach_prancha_5min', description: "Manteve a Prancha Frontal por 5 minutos", linkedExerciseId: 'prancha_frontal', durationCondition: 5, expReward: 300, titleReward: "Núcleo de Ferro", statBonuses: {'VIT': 4}),
  Achievement(id: 'ach_prancha_10min', description: "Manteve a Prancha Frontal por 10 minutos", linkedExerciseId: 'prancha_frontal', durationCondition: 10, expReward: 600, titleReward: "Resistência Absoluta", statBonuses: {'VIT': 8}),
  Achievement(id: 'ach_100_abdominais', description: "Realizou 100 Abdominais Supra Solo em uma única sessão", linkedExerciseId: 'abdominal_supra_solo', repsCondition: 100, expReward: 250, titleReward: "Abdômen de Ferro", statBonuses: {'VIT': 3}),
  Achievement(id: 'ach_200_abdominais', description: "Realizou 200 Abdominais Supra Solo em uma única sessão", linkedExerciseId: 'abdominal_supra_solo', repsCondition: 200, expReward: 500, titleReward: "Tanque Humano", statBonuses: {'VIT': 6}),

  // Conquistas de Agilidade
  Achievement(id: 'ach_corrida_60min', description: "Correu 60 minutos na Corrida Esteira", linkedExerciseId: 'corrida_esteira', durationCondition: 60, expReward: 400, titleReward: "O Maratonista Incansável", statBonuses: {'AGI': 5, 'VIT': 2}),
  Achievement(id: 'ach_corrida_30min', description: "Correu 30 minutos na Corrida Esteira", linkedExerciseId: 'corrida_esteira', durationCondition: 30, expReward: 200, titleReward: "Corredor Persistente", statBonuses: {'AGI': 3}),
  Achievement(id: 'ach_bike_45min', description: "Pedalou 45 minutos na Bicicleta Ergométrica", linkedExerciseId: 'bicicleta_ergometrica', durationCondition: 45, expReward: 250, titleReward: "Ciclista Determinado", statBonuses: {'AGI': 3, 'VIT': 2}),
  Achievement(id: 'ach_mountain_climber_300', description: "Realizou 300 Mountain Climbers em uma única sessão", linkedExerciseId: 'mountain_climber', repsCondition: 300, expReward: 300, titleReward: "Montanhista Ágil", statBonuses: {'AGI': 4}),

  // Conquistas de Inteligência (exercícios de coordenação e técnica)
  Achievement(id: 'ach_dead_bug_100', description: "Realizou 100 Dead Bugs em uma única sessão", linkedExerciseId: 'dead_bug', repsCondition: 100, expReward: 200, titleReward: "Coordenação Perfeita", statBonuses: {'INT': 3, 'VIT': 2}),
  Achievement(id: 'ach_bird_dog_10min', description: "Manteve o Bird Dog por 10 minutos", linkedExerciseId: 'bird_dog', durationCondition: 10, expReward: 250, titleReward: "Equilibrio Mental", statBonuses: {'INT': 4}),
  Achievement(id: 'ach_russian_twist_200', description: "Realizou 200 Russian Twists em uma única sessão", linkedExerciseId: 'russian_twist', repsCondition: 200, expReward: 300, titleReward: "Mente Afiada", statBonuses: {'INT': 4, 'AGI': 2}),

  // Conquistas de Percepção (exercícios de equilíbrio e propriocepção)
  Achievement(id: 'ach_10_barras', description: "Realizou 10 Barras Fixas Pegada Pronada", linkedExerciseId: 'barra_fixa_pronada', repsCondition: 10, expReward: 350, titleReward: "Rei da Barra", statBonuses: {'PER': 4, 'FOR': 3}),
  Achievement(id: 'ach_20_barras', description: "Realizou 20 Barras Fixas Pegada Pronada", linkedExerciseId: 'barra_fixa_pronada', repsCondition: 20, expReward: 700, titleReward: "Mestre das Alturas", statBonuses: {'PER': 8, 'FOR': 5}),
  Achievement(id: 'ach_prancha_lateral_5min', description: "Manteve a Prancha Lateral Direita por 5 minutos", linkedExerciseId: 'prancha_lateral_direita', durationCondition: 5, expReward: 250, titleReward: "Equilíbrio Lateral", statBonuses: {'PER': 3, 'VIT': 2}),
  Achievement(id: 'ach_step_up_100', description: "Realizou 100 Step Ups em uma única sessão", linkedExerciseId: 'step_up', repsCondition: 100, expReward: 200, titleReward: "Coordenação Superior", statBonuses: {'PER': 3, 'AGI': 2}),

  // Conquistas Mistas (múltiplos atributos)
  Achievement(id: 'ach_burpees_50', description: "Realizou 50 Burpees em uma única sessão", linkedExerciseId: 'burpees', repsCondition: 50, expReward: 400, titleReward: "Guerreiro Completo", statBonuses: {'FOR': 2, 'VIT': 3, 'AGI': 3}),
  Achievement(id: 'ach_crossfit_combo', description: "Completou 100 Flexões + 50 Barras + 30min Corrida na mesma sessão", linkedExerciseId: 'combo_crossfit', expReward: 1000, titleReward: "Atleta Supremo", statBonuses: {'FOR': 5, 'VIT': 5, 'AGI': 5, 'PER': 3}),

  // Conquistas de Levantamento Pesado
  Achievement(id: 'ach_deadlift_200kg', description: "Realizou Levantamento Terra com 200kg (1 rep)", linkedExerciseId: 'levantamento_terra', weightCondition: 200, repsCondition: 1, expReward: 800, titleReward: "Força Titânica", statBonuses: {'FOR': 8, 'VIT': 4}),
  Achievement(id: 'ach_leg_press_300kg', description: "Realizou Leg Press 45° com 300kg (1 rep)", linkedExerciseId: 'leg_press_45', weightCondition: 300, repsCondition: 1, expReward: 600, titleReward: "Máquina de Pernas", statBonuses: {'FOR': 6, 'VIT': 3}),
];

// --- TELA DE SELEÇÃO DE EXERCÍCIOS ---
class ExerciseSelectionScreen extends StatefulWidget {
  final String dayOfWeek;
  final Function(List<PlannedExercise>) onSavePlan;
  final List<PlannedExercise>? existingExercises;

  const ExerciseSelectionScreen({
    required this.dayOfWeek,
    required this.onSavePlan,
    this.existingExercises,
    super.key,
  });

  @override
  State<ExerciseSelectionScreen> createState() => _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  // Usar a lista global de exercícios
  final List<Exercise> _allExercises = allMasterExercisesList;
  List<Exercise> _filteredExercises = [];
  final List<PlannedExercise> _selectedExercisesForPlan = [];
  final TextEditingController _nameFilterController = TextEditingController();
  String? _selectedBodyPartFilter;
  List<String> _bodyParts = [];

  @override
  void initState() {
    super.initState();
    _filteredExercises = List.from(_allExercises);
    _bodyParts = _allExercises.map((e) => e.bodyPart).toSet().toList()..sort();
    _nameFilterController.addListener(_filterExercises);
    
    if (widget.existingExercises != null) {
      _selectedExercisesForPlan.addAll(widget.existingExercises!);
    }
  }

  @override
  void dispose() {
    _nameFilterController.removeListener(_filterExercises);
    _nameFilterController.dispose();
    super.dispose();
  }

  // Helper para tradução
  String _t(String key) {
    final languageService = context.read<LanguageService>();
    return TranslationService.get(key, languageService.currentLanguageCode);
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

  void _filterExercises() {
    String query = _nameFilterController.text.toLowerCase();
    setState(() {
      _filteredExercises = _allExercises.where((exercise) {
        final nameMatches = exercise.name.toLowerCase().contains(query);
        final bodyPartMatches = _selectedBodyPartFilter == null || exercise.bodyPart == _selectedBodyPartFilter;
        return nameMatches && bodyPartMatches;
      }).toList();
    });
  }


  void _showSetsRepsDialog(Exercise exercise) {
    final setsController = TextEditingController(text: "3");
    final repsOrDurationController = TextEditingController(text: exercise.isTimeBased ? "15" : "10");
    final existingIndex = _selectedExercisesForPlan.indexWhere((pe) => pe.exercise.id == exercise.id);
    if (existingIndex != -1) {
      final existingPlan = _selectedExercisesForPlan[existingIndex];
      setsController.text = existingPlan.sets.toString();
      if (exercise.isTimeBased) {
        repsOrDurationController.text = existingPlan.durationMinutes?.toString() ?? "15";
      } else {
        repsOrDurationController.text = existingPlan.reps?.toString() ?? "10";
      }
    }
    showStyledDialog(
      passedContext: context,
      titleText: "${_t('configure')} ${exercise.name}",
      icon: Icons.fitness_center,
      iconColor: accentColorBlue,
      contentWidgets: [
        TextField( 
          controller: setsController, 
          keyboardType: TextInputType.number, 
          style: const TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: _t('series'), 
            labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColorBlue.withOpacity(0.5))),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: accentColorBlue)),
          ),
        ),
        const SizedBox(height: 10),
        TextField( 
          controller: repsOrDurationController, 
          keyboardType: TextInputType.number, 
          style: const TextStyle(color: textColor),
          decoration: InputDecoration( 
            labelText: exercise.isTimeBased ? "Duração (minutos)" : "Repetições",
            labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentColorBlue.withOpacity(0.5))),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: accentColorBlue)),
          ),
        ),
      ],
      actions: [
        buildDialogButton(context, "Cancelar", () => Navigator.of(context).pop(), false),
        buildDialogButton(context, existingIndex != -1 ? "Atualizar" : "Adicionar", () {
          final sets = int.tryParse(setsController.text) ?? 3;
          final repsOrDurationValue = int.tryParse(repsOrDurationController.text) ?? (exercise.isTimeBased ? 15 : 10);
          setState(() {
            PlannedExercise plannedEx;
            if (exercise.isTimeBased) {
              plannedEx = PlannedExercise(exercise: exercise, sets: sets, durationMinutes: repsOrDurationValue);
            } else {
              plannedEx = PlannedExercise(exercise: exercise, sets: sets, reps: repsOrDurationValue);
            }
            if (existingIndex != -1) { 
              _selectedExercisesForPlan[existingIndex] = plannedEx;
            } else { 
              _selectedExercisesForPlan.add(plannedEx); 
            }
          });
          Navigator.of(context).pop();
        }, true),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar( title: Text("${_t('exercisesFor')} ${widget.dayOfWeek}", style: const TextStyle(color: textColor, fontSize: 18)),
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: accentColorBlue),
        actions: [ IconButton( icon: const Icon(Icons.save_alt_rounded, color: accentColorBlue), tooltip: _t('saveWorkout'),
            onPressed: () {
              if (_selectedExercisesForPlan.isNotEmpty) { 
                widget.onSavePlan(_selectedExercisesForPlan); 
                Navigator.of(context).pop();
              } else { 
                showStyledDialog(
                  passedContext: context,
                  titleText: _t('warning'),
                  icon: Icons.warning_amber_rounded,
                  iconColor: Colors.orangeAccent,
                  contentWidgets: [
                    Text("Adicione ao menos um exercício ao plano.", style: TextStyle(color: textColor))
                  ],
                  actions: [
                    buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true)
                  ]
                );
              }
            },)],),
      body: Column( children: [
        Padding( padding: const EdgeInsets.all(12.0),
          child: Row( children: [
            Expanded( child: TextField( controller: _nameFilterController,
                decoration: InputDecoration( hintText: "Buscar exercício...", hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.search, color: accentColorBlue.withOpacity(0.7), size: 20),
                  filled: true, fillColor: panelBgColor.withOpacity(0.7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),),
                style: const TextStyle(color: textColor),),),
            const SizedBox(width: 10),
            Container( padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration( color: panelBgColor.withOpacity(0.7), borderRadius: BorderRadius.circular(20),),
              child: DropdownButtonHideUnderline( child: DropdownButton<String>(
                value: _selectedBodyPartFilter, hint: Text("Grupo", style: TextStyle(color: textColor.withOpacity(0.7))),
                dropdownColor: panelBgColor, icon: Icon(Icons.filter_list_rounded, color: accentColorBlue.withOpacity(0.7)),
                style: const TextStyle(color: textColor),
                items: [ DropdownMenuItem<String>(value: null, child: Text("Todos Grupos", style: TextStyle(color: textColor.withOpacity(0.9)))),
                  ..._bodyParts.map((part) => DropdownMenuItem<String>(value: part, child: Text(part))),],
                onChanged: (value) { setState(() { _selectedBodyPartFilter = value; _filterExercises();});},),),),],),),
        if (_selectedExercisesForPlan.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: accentColorPurple.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: accentColorPurple, size: 20),
                SizedBox(width: 8),
                Text(
                  "Exercícios Selecionados: ${_selectedExercisesForPlan.length}",
                  style: TextStyle(
                    color: accentColorPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 14
                  ),
                ),
              ],
            ),
          ),
        Expanded( child: _filteredExercises.isEmpty
            ? Center(child: Text("Nenhum exercício encontrado.", style: TextStyle(color: textColor.withOpacity(0.7))))
            : ListView.builder( padding: const EdgeInsets.symmetric(horizontal: 8.0), itemCount: _filteredExercises.length,
            itemBuilder: (context, index) {
              final exercise = _filteredExercises[index];
              final isAdded = _selectedExercisesForPlan.any((pe) => pe.exercise.id == exercise.id);
              final plannedExercise = isAdded ? _selectedExercisesForPlan.firstWhere((pe) => pe.exercise.id == exercise.id) : null;
              String subtitleText = exercise.bodyPart;
              if (isAdded && plannedExercise != null) {
                if (exercise.isTimeBased) { subtitleText = "${plannedExercise.sets} séries x ${plannedExercise.durationMinutes ?? 0} min";
                } else { subtitleText = "${plannedExercise.sets} séries x ${plannedExercise.reps ?? 0} reps";}}
              return Card( color: panelBgColor.withOpacity(isAdded ? 0.9 : 0.6), margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isAdded ? accentColorPurple : Colors.transparent, width: 1)),
                child: ListTile( title: Text(exercise.name, style: TextStyle(color: isAdded ? accentColorPurple : textColor, fontWeight: isAdded ? FontWeight.bold : FontWeight.normal)),
                  subtitle: Text( subtitleText, style: TextStyle(color: isAdded ? accentColorPurple.withOpacity(0.8) : textColor.withOpacity(0.6))),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isAdded)
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              _selectedExercisesForPlan.removeWhere((pe) => pe.exercise.id == exercise.id);
                            });
                            // Manter a mensagem de feedback visual na tela de seleção ao remover.
                             _showStyledDialog(
                                context: context,
                                titleText: "Exercício Removido",
                                icon: Icons.remove_circle_outline,
                                iconColor: Colors.redAccent,
                                contentWidgets: [
                                  Text("${exercise.name} removido do plano.", style: TextStyle(color: textColor)),
                                ],
                                actions: [
                                  _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
                                ],
                              );
                          },
                        ),
                      IconButton(
                        icon: Icon(
                          isAdded ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                          color: isAdded ? accentColorPurple : accentColorBlue,
                        ),
                        onPressed: () => _showSetsRepsDialog(exercise),
                      ),
                    ],
                  ),
                  onTap: () => _showSetsRepsDialog(exercise),),);},),), // Adicionado parêntese
        if (_selectedExercisesForPlan.isNotEmpty)
          Padding( padding: const EdgeInsets.all(12.0),
            child: Text("${_selectedExercisesForPlan.length} exercícios no plano para ${widget.dayOfWeek}.", style: const TextStyle(color: accentColorPurple, fontWeight: FontWeight.bold)),)
      ],),);}}

// --- MODELO PARA LOG DE SÉRIE ---
class WorkoutSetLog {
  final String exerciseId;
  final String exerciseName;
  final int setNumber;
  final int? repsDone;
  final int? durationAchievedMinutes;
  final double? weightUsed;
  final DateTime timestamp;

  WorkoutSetLog({
    required this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    this.repsDone,
    this.durationAchievedMinutes,
    this.weightUsed,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'setNumber': setNumber,
      'repsDone': repsDone,
      'durationAchievedMinutes': durationAchievedMinutes,
      'weightUsed': weightUsed,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

// --- TELA DE EXECUÇÃO DE TREINO ---
class WorkoutExecutionScreen extends StatefulWidget {
  final String dayOfWeek;
  final List<PlannedExercise> exercises;
  final bool isResuming;
  final int restTime; // Novo campo

  const WorkoutExecutionScreen({
    required this.dayOfWeek,
    required this.exercises,
    this.isResuming = false,
    required this.restTime, // Novo parâmetro obrigatório
    super.key,
  });

  @override
  State<WorkoutExecutionScreen> createState() => _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState extends State<WorkoutExecutionScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsOrDurationController = TextEditingController();
  int _currentExerciseIndex = 0;
  int _currentSetNumber = 1;
  bool _isResting = false;
  int _currentRestTimeLeft = 0;
  int _defaultRestTimeSeconds = 60;
  Timer? _timer;
  bool _newPRHitThisSet = false;
  double? _currentExercisePR;
  final List<WorkoutSetLog> _workoutSessionLog = [];
  bool _isSavingLog = false;
  bool _hasWorkoutCompletionProcessStarted = false;
  String _currentPlayerName = "Jogador";
  int _currentPlayerLevel = 1;
  double _currentPlayerExp = 0.0;
  int _currentPlayerSkillPoints = 0;
  Map<String, bool> _userCompletedAchievementsMap = {};
  final List<Achievement> _completedAchievementsInSession = [];
  bool _isSelectingExercise = true;
  List<int> _completedExerciseIndices = [];

  @override
  void initState() {
    super.initState();
    _defaultRestTimeSeconds = widget.restTime; // Inicializa com o valor passado
    _loadInitialUserDataForWorkout();
    if (widget.isResuming) {
      _loadInProgressWorkout();
    }
  }

  Future<void> _loadInitialUserDataForWorkout() async {
    if (!mounted) return;
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _currentPlayerLevel = data['level'] ?? 1;
              _currentPlayerExp = (data['exp'] ?? 0.0).toDouble();
              _currentPlayerSkillPoints = data['availableSkillPoints'] ?? 0;
              _currentPlayerName = data['playerName'] ?? "Jogador";
              if (data.containsKey('completedAchievements') && data['completedAchievements'] is Map) {
                _userCompletedAchievementsMap = Map<String, bool>.from(data['completedAchievements']);
              }
            });
          }
        }
      } catch (e) {
        print("Erro ao carregar dados do usuário para o treino: $e");
      }
    }
    _loadDataForCurrentExercise();
  }

  Future<void> _loadInProgressWorkout() async {
    if (!mounted) return;
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _completedExerciseIndices = List<int>.from(data['completedExerciseIndices'] ?? []);
              _currentExerciseIndex = data['currentExerciseIndex'] ?? 0;
              _currentSetNumber = data['currentSetNumber'] ?? 1;
            });
          }
        }
      } catch (e) {
        print("Erro ao carregar treino em progresso: $e");
      }
    }
  }

  Future<void> _saveWorkoutProgress() async {
    if (!mounted) return;
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'completedExerciseIndices': _completedExerciseIndices,
          'currentExerciseIndex': _currentExerciseIndex,
          'currentSetNumber': _currentSetNumber,
        });
      } catch (e) {
        print("Erro ao salvar progresso do treino: $e");
      }
    }
  }

  Future<void> _loadDataForCurrentExercise() async {
    if (!mounted) return;
    setState(() { _newPRHitThisSet = false; });
    if (widget.exercises.isNotEmpty && _currentExerciseIndex < widget.exercises.length) {
      final currentPlannedExercise = widget.exercises[_currentExerciseIndex];
      final exerciseId = currentPlannedExercise.exercise.id;
      _weightController.text = currentPlannedExercise.lastWeight?.toStringAsFixed(1) ?? "";
      if (currentPlannedExercise.exercise.isTimeBased) {
        _repsOrDurationController.text = currentPlannedExercise.durationMinutes?.toString() ?? "";
      } else {
        _repsOrDurationController.text = currentPlannedExercise.reps?.toString() ?? "";
      }
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && !currentPlannedExercise.exercise.isTimeBased) {
        try {
          DocumentSnapshot prDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('exercisePRs')
              .doc(exerciseId)
              .get();
          if (mounted) {
            if (prDoc.exists && prDoc.data() != null) {
              final data = prDoc.data() as Map<String, dynamic>;
              setState(() { _currentExercisePR = (data['maxWeight'] as num?)?.toDouble(); });
            } else {
              setState(() { _currentExercisePR = null; });
            }
          }
        } catch (e) {
          print("Erro ao carregar PR para $exerciseId: $e");
          if (mounted) {
            setState(() { _currentExercisePR = null; });
          }
        }
      } else {
        if (mounted) {
          setState(() { _currentExercisePR = null; });
        }
      }
    }
  }

  void _showWorkoutCompleteDialog() {
    if (!mounted) return;
    if (_hasWorkoutCompletionProcessStarted && _isSavingLog) return;
    _hasWorkoutCompletionProcessStarted = true;

    showStyledDialog(
      passedContext: context,
      titleText: "Treino Concluído!",
      icon: Icons.fitness_center_rounded,
      iconColor: greenStatColor,
      contentWidgets: [
        Text(
          "Parabéns, $_currentPlayerName!\nVocê completou o treino de ${widget.dayOfWeek}.",
          textAlign: TextAlign.center,
          style: const TextStyle(color: textColor, fontSize: 16)
        ),
      ],
      actions: [
        // O botão de salvar log será adicionado e gerenciará seu próprio estado de loading
        buildDialogButton(context, "FINALIZAR E SALVAR LOG", () async {
          if (mounted) {
            setState(() { _isSavingLog = true; });
          }
          // Passar o contexto do Navigator para fechar o diálogo após salvar
          await _saveWorkoutLogAndExit(context);
        }, true)
      ],
    ).then((_) {
      // Esta parte é executada depois que o dialog é fechado. Resetamos o flag.
      _hasWorkoutCompletionProcessStarted = false;
    });
  }

  Widget _buildRestingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "DESCANSO",
          style: TextStyle(color: accentColorPurple, fontSize: 32, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center
        ),
        const SizedBox(height: 20),
        Text(
          "${(_currentRestTimeLeft ~/ 60).toString().padLeft(2, '0')}:${(_currentRestTimeLeft % 60).toString().padLeft(2, '0')}",
          style: const TextStyle(color: textColor, fontSize: 80, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_alarm_rounded),
          label: const Text("+30 Segundos"),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColorBlue.withOpacity(0.8),
            foregroundColor: textColor,
            padding: const EdgeInsets.symmetric(vertical: 12)
          ),
          onPressed: () => _addSecondsToRest(30),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _skipRest,
          child: const Text("PULAR DESCANSO", style: TextStyle(color: accentColorPurple, fontSize: 16)),
        ),
        if (widget.exercises.isNotEmpty && 
            _currentExerciseIndex == widget.exercises.length - 1 && 
            _currentSetNumber > widget.exercises[_currentExerciseIndex].sets && 
            _isResting)
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: textColor,
                padding: const EdgeInsets.symmetric(vertical: 15)
              ),
              child: const Text(
                "FINALIZAR TREINO",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              onPressed: () {
                _timer?.cancel();
                _showWorkoutCompleteDialog();
              }
            )
          )
      ]
    );
  }

  Widget _buildWorkoutView(PlannedExercise plannedEx, Exercise actualEx) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: panelBgColor.withOpacity(0.7),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    actualEx.name,
                    style: const TextStyle(color: accentColorBlue, fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Série: $_currentSetNumber de ${plannedEx.sets}",
                    style: const TextStyle(color: textColor, fontSize: 18)
                  ),
                  Text(
                    actualEx.isTimeBased
                        ? "Duração Alvo: ${plannedEx.durationMinutes ?? '-'} min"
                        : "Repetições Alvo: ${plannedEx.reps ?? '-'}",
                    style: const TextStyle(color: textColor, fontSize: 18)
                  ),
                  if (!actualEx.isTimeBased)
                    Text(
                      "Última Carga: ${plannedEx.lastWeight?.toStringAsFixed(1) ?? 'N/A'} kg",
                      style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 16)
                    ),
                  if (!actualEx.isTimeBased && _currentExercisePR != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "Seu Recorde: ${_currentExercisePR!.toStringAsFixed(1)} kg",
                        style: TextStyle(color: prColor, fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          if (!actualEx.isTimeBased)
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: textColor, fontSize: 18),
              decoration: InputDecoration(
                labelText: "Peso Utilizado (kg)",
                labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                filled: true,
                fillColor: panelBgColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none
                ),
                prefixIcon: Icon(Icons.fitness_center_rounded, color: accentColorBlue.withOpacity(0.7)),
              ),
            ),
          if (!actualEx.isTimeBased) const SizedBox(height: 15),
          TextField(
            controller: _repsOrDurationController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: textColor, fontSize: 18),
            decoration: InputDecoration(
              labelText: actualEx.isTimeBased ? "Tempo Realizado (minutos)" : "Repetições Feitas",
              labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
              filled: true,
              fillColor: panelBgColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none
              ),
              prefixIcon: Icon(
                actualEx.isTimeBased ? Icons.timer_outlined : Icons.repeat_rounded,
                color: accentColorBlue.withOpacity(0.7)
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finishSet() async {
    if (!mounted) return;
    
    // Previne múltiplas execuções simultâneas
    if (_isResting) {
      print("Já está em período de descanso, ignorando clique em finalizar série");
      return;
    }
    
    final double weight = double.tryParse(_weightController.text) ?? 0;
    final int repsOrDurationValue = int.tryParse(_repsOrDurationController.text) ?? 0;
    
    if (mounted) {
      setState(() { _newPRHitThisSet = false; });
    }

    if (_currentExerciseIndex >= widget.exercises.length) return;
    final currentPlannedExercise = widget.exercises[_currentExerciseIndex];
    final currentExercise = currentPlannedExercise.exercise;

    if (repsOrDurationValue <= 0) {
      if (mounted) {
        showStyledDialog(
          passedContext: context,
          titleText: "Erro",
          icon: Icons.error_outline,
          iconColor: Colors.redAccent,
          contentWidgets: [
            Text(
              currentExercise.isTimeBased
                  ? "Duração deve ser maior que zero."
                  : "Repetições devem ser maiores que zero.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: textColor, fontSize: 16)
            )
          ],
          actions: [
            buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true)
          ],
        );
      }
      return;
    }

    _workoutSessionLog.add(WorkoutSetLog(
      exerciseId: currentExercise.id,
      exerciseName: currentExercise.name,
      setNumber: _currentSetNumber,
      repsDone: currentExercise.isTimeBased ? null : repsOrDurationValue,
      durationAchievedMinutes: currentExercise.isTimeBased ? repsOrDurationValue : null,
      weightUsed: currentExercise.isTimeBased ? null : weight,
      timestamp: DateTime.now(),
    ));

    await _checkAndProcessExerciseAchievements(
      currentExercise,
      weight,
      currentExercise.isTimeBased ? 0 : repsOrDurationValue,
      currentExercise.isTimeBased ? repsOrDurationValue : 0
    );

    if (!currentExercise.isTimeBased) {
      widget.exercises[_currentExerciseIndex].lastWeight = weight;
      if (weight > (_currentExercisePR ?? 0)) {
        if (mounted) {
          setState(() {
            _currentExercisePR = weight;
            _newPRHitThisSet = true;
          });
        }
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .collection('exercisePRs')
                .doc(currentExercise.id)
                .set(
                  {
                    'maxWeight': weight,
                    'timestamp': FieldValue.serverTimestamp()
                  },
                  SetOptions(merge: true)
                );
            print("Novo PR de ${currentExercise.name} salvo: ${weight}kg");
            _sendFriendNotification('bateu o novo recorde pessoal de ${weight.toStringAsFixed(1)}kg no ${currentExercise.name}!');
            _sendGuildNotification('bateu o novo recorde pessoal de ${weight.toStringAsFixed(1)}kg no ${currentExercise.name}!');
            if (mounted && _newPRHitThisSet) {
              showStyledDialog(
                passedContext: context,
                titleText: "NOVO RECORDE!",
                icon: Icons.emoji_events_rounded,
                iconColor: prColor,
                contentWidgets: [
                  Text(
                    '✨ ${currentExercise.name}: ${weight.toStringAsFixed(1)}kg! ✨',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)
                  )
                ],
                actions: [
                  buildDialogButton(context, "INCRÍVEL!", () => Navigator.of(context).pop(), true)
                ],
              );
            }
          } catch (e) {
            print("Erro ao salvar PR para ${currentExercise.name}: $e");
            if (mounted) {
              showStyledDialog(
                passedContext: context,
                titleText: "Erro",
                icon: Icons.error_outline,
                iconColor: Colors.redAccent,
                contentWidgets: [
                  Text(
                    "Erro ao salvar novo recorde.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: textColor, fontSize: 16)
                  )
                ],
                actions: [
                  buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true)
                ],
              );
            }
          }
        }
      }
    }
    print("=== DEBUG FINISHSET ===");
    print("Série ${_currentSetNumber} de ${currentExercise.name} finalizada.");
    print("Total de séries planejadas: ${currentPlannedExercise.sets}");
    print("Exercício atual index: $_currentExerciseIndex");
    print("Total de exercícios: ${widget.exercises.length}");
    print("Exercícios completados: $_completedExerciseIndices");
    print("Iniciando timer de descanso...");
    _startRestTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _weightController.dispose();
    _repsOrDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // O WillPopScope controla a ação do botão de voltar (tanto da seta quanto do Android).
    return WillPopScope(
      onWillPop: () async {
        // Se o treino já foi concluído, permite sair sem perguntar.
        if (_currentExerciseIndex >= widget.exercises.length) {
          return true;
        }

        // Mostra um diálogo de confirmação antes de sair.
        final bool? shouldPop = await showStyledDialog<bool>(
          passedContext: context,
          titleText: "Sair do Treino?",
          icon: Icons.exit_to_app,
          iconColor: Colors.redAccent,
          contentWidgets: [
            Text(
              "Seu progresso neste treino não será salvo. Deseja continuar?",
              textAlign: TextAlign.center,
              style: const TextStyle(color: textColor, fontSize: 16),
            ),
          ],
          actions: [
            buildDialogButton(context, "Sair", () => Navigator.of(context).pop(true), true),
            buildDialogButton(context, "Cancelar", () => Navigator.of(context).pop(false), false),
          ],
        );

        // Retorna a escolha do usuário (true para sair, false ou null para ficar).
        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor: primaryColor,
        // Sua AppBar já estava correta, garantindo a seta e removendo o 'X'.
        // A mudança acima no onWillPop é o que faz a seta funcionar.
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text("Executando - ${widget.dayOfWeek}", style: const TextStyle(color: textColor, fontSize: 18)),
          // A linha abaixo garante que a seta de voltar apareça.
          automaticallyImplyLeading: true,
          // A linha abaixo garante que nenhum outro ícone (como o 'X') apareça à direita.
          actions: const [],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: _isSavingLog
              ? const Center(child: CircularProgressIndicator(color: accentColorPurple))
              : _isResting
                  ? _buildRestingView()
                  : _isSelectingExercise
                      ? _buildExerciseSelectionView()
                      : _currentExerciseIndex < widget.exercises.length
                          ? _buildExerciseCard()
                          : _buildWorkoutCompleteCard(),
        ),
        bottomNavigationBar: _currentExerciseIndex < widget.exercises.length && !_isSelectingExercise
            ? _buildBottomNavigationBar()
            : _isSelectingExercise
                ? _buildFinishWorkoutButton()
                : null,
      ),
    );
  }

  void _moveToNextSetOrExercise() {
    if (!mounted) return;
    print("=== MOVENDO PARA PRÓXIMA SÉRIE/EXERCÍCIO ===");
    print("Série atual: $_currentSetNumber");
    print("Exercício atual index: $_currentExerciseIndex");
    setState(() {
      _isResting = false;
      if (_currentExerciseIndex < widget.exercises.length) {
        final currentPlannedExercise = widget.exercises[_currentExerciseIndex];
        print("Total de séries do exercício: ${currentPlannedExercise.sets}");
        // Verifica se a série que acabou de terminar é a última deste exercício
        if (_currentSetNumber >= currentPlannedExercise.sets) {
          print("Exercício completado! Passando para seleção do próximo.");
          // Marca o exercício atual como concluído se ainda não estiver
          if (!_completedExerciseIndices.contains(_currentExerciseIndex)) {
            _completedExerciseIndices.add(_currentExerciseIndex);
            _saveWorkoutProgress(); // Salva o progresso (exercício concluído)
          }

          // Move para a seleção do próximo exercício
          setState(() {
            _isSelectingExercise = true;
            // O índice do próximo exercício e o número da série serão resetados/definidos
            // quando o usuário selecionar o próximo exercício na tela de seleção.
            // O _currentSetNumber será resetado para 1 quando um novo exercício for selecionado.
          });
        } else {
          // Se ainda há séries para o exercício atual, incrementa o contador de séries e prepara para a próxima série
          print("Avançando para próxima série do mesmo exercício");
          _currentSetNumber++;
          print("Nova série: $_currentSetNumber");
          if (currentPlannedExercise.exercise.isTimeBased) {
            _repsOrDurationController.text = currentPlannedExercise.durationMinutes?.toString() ?? "";
          } else {
            _repsOrDurationController.text = currentPlannedExercise.reps?.toString() ?? "";
          }
          // Não muda _isSelectingExercise aqui, permanece false para continuar na tela de execução
        }
      } else if (_completedExerciseIndices.length == widget.exercises.length) {
        // Este caso trata a situação onde o _currentExerciseIndex já excedeu o limite
        // e todos os exercícios estão marcados como concluídos, garantindo que o diálogo apareça.
        // Pode acontecer se o estado for restaurado ou houver navegação.
        print("DEBUG: Finalizando treino via else if branch (todos exercícios concluídos).");
        _showWorkoutCompleteDialog();
      } else {
         // Este caso pode ocorrer se houver um estado inconsistente (ex: _currentExerciseIndex fora do limite,
         // mas nem todos os exercícios marcados como concluídos). Como fallback, volta para a seleção.
         print("DEBUG: Estado inconsistente, voltando para seleção de exercícios.");
         setState(() {
           _isSelectingExercise = true;
         });
      }
    });
  }

  Future<void> _saveWorkoutLogAndExit(BuildContext dialogContextToPop) async {
    if (!mounted) return;

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("Usuário não logado. Log não será salvo.");
      if (mounted) {
        if (Navigator.canPop(dialogContextToPop)) {
          Navigator.of(dialogContextToPop).pop();
        }
        showStyledDialog(
          passedContext: context,
          titleText: "Erro",
          icon: Icons.error_outline,
          iconColor: Colors.redAccent,
          contentWidgets: [
            Text(
              "Erro: Usuário não logado. Log não salvo.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: textColor, fontSize: 16),
            ),
          ],
          actions: [
            buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
          ],
        );
        setState(() {
          _isSavingLog = false;
        });
        _hasWorkoutCompletionProcessStarted = false;
      }
      return;
    }

    final List<Map<String, dynamic>> logEntriesMap = _workoutSessionLog.map((log) => log.toMap()).toList();
    bool success = false;
    String? errorMessage;

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      DocumentReference sessionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('workoutSessions')
          .doc();
      batch.set(sessionRef, {
        'dayOfWeek': widget.dayOfWeek,
        'sessionTimestamp': FieldValue.serverTimestamp(),
        'logEntries': logEntriesMap,
      });

      final List<Map<String, dynamic>> updatedPlannedExercisesMap = widget.exercises.map((pe) => pe.toMap()).toList();
      DocumentReference planRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('workoutPlans')
          .doc(widget.dayOfWeek);
      batch.set(planRef, {
        'exercises': updatedPlannedExercisesMap,
      }, SetOptions(merge: true));

      // Limpar dados de progresso do treino
      batch.update(FirebaseFirestore.instance.collection('users').doc(currentUser.uid), {
        'inProgressWorkout': false,
        'inProgressWorkoutDay': null,
        'completedExerciseIndices': [],
        'currentExerciseIndex': 0,
        'currentSetNumber': 1,
      });

      await batch.commit();
      success = true;
    } catch (e) {
      print("Erro ao salvar log do treino no Firebase: $e");
      errorMessage = "Erro ao salvar log. Tente novamente.";
    } finally {
      if (mounted) {
        if (Navigator.canPop(dialogContextToPop)) {
          Navigator.of(dialogContextToPop).pop();
        }

        setState(() {
          _isSavingLog = false;
        });

        if (success) {
          showStyledDialog(
            passedContext: context,
            titleText: "Sucesso",
            icon: Icons.check_circle_rounded,
            iconColor: Colors.green,
            contentWidgets: [
              Text(
                "Log do treino salvo com sucesso!",
                textAlign: TextAlign.center,
                style: const TextStyle(color: textColor, fontSize: 16),
              ),
            ],
            actions: [
              buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
            ],
          ).then((_) {
            // Executa após o diálogo de sucesso ser fechado
            if (mounted && Navigator.canPop(context)) {
              _hasWorkoutCompletionProcessStarted = false;
              Navigator.of(context).pop(); // Volta para a tela anterior (TreinoScreen)
            }
          });
        } else {
          showStyledDialog(
            passedContext: context,
            titleText: "Erro",
            icon: Icons.error_outline,
            iconColor: Colors.redAccent,
            contentWidgets: [
              Text(
                errorMessage ?? "Ocorreu um erro.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: textColor, fontSize: 16),
              ),
            ],
            actions: [
              buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
            ],
          );
          _hasWorkoutCompletionProcessStarted = false;
        }
      }
    }
  }

  void _addSecondsToRest(int seconds) {
    if (_isResting && mounted) {
      _timer?.cancel();
      setState(() {
        _currentRestTimeLeft += seconds;
        _defaultRestTimeSeconds = _currentRestTimeLeft;
      });
      _startRestTimer();
    }
  }

  void _skipRest() {
    if (!mounted) return;
    _timer?.cancel();
    _moveToNextSetOrExercise();
  }


  Future<T?> showStyledDialog<T>({
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

  Future<void> _checkAndProcessExerciseAchievements(
    Exercise currentExercise,
    double weightAchieved,
    int repsAchieved,
    int durationAchieved
  ) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || !mounted) return;
    
    print("=== PROCESSANDO CONQUISTAS ===");
    print("Exercício: ${currentExercise.name}");
    print("Peso: $weightAchieved, Reps: $repsAchieved, Duração: $durationAchieved");
    
    List<Achievement> newlyCompletedAchievementsInThisSet = [];

    for (var achievement in allPossibleAchievements) {
      if (achievement.linkedExerciseId == currentExercise.id &&
          !(_userCompletedAchievementsMap[achievement.id] ?? false) &&
          !_completedAchievementsInSession.any((ach) => ach.id == achievement.id)) {
        bool conditionMet = false;
        if (currentExercise.isTimeBased && achievement.durationCondition != null) {
          if (durationAchieved >= achievement.durationCondition!) conditionMet = true;
        } else if (!currentExercise.isTimeBased && achievement.weightCondition != null && achievement.repsCondition != null) {
          if (weightAchieved >= achievement.weightCondition! && repsAchieved >= achievement.repsCondition!) conditionMet = true;
        } else if (!currentExercise.isTimeBased && achievement.repsCondition != null && achievement.weightCondition == null) {
          if (repsAchieved >= achievement.repsCondition!) conditionMet = true;
        }
        
        if (conditionMet) {
          print("CONQUISTA DESBLOQUEADA: ${achievement.description}");
          newlyCompletedAchievementsInThisSet.add(achievement);
        }
      }
    }

    if (newlyCompletedAchievementsInThisSet.isNotEmpty) {
      print("Total de conquistas para salvar: ${newlyCompletedAchievementsInThisSet.length}");
      
      DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      double totalExpGainedFromThisSetAchievements = 0;
      for (var ach in newlyCompletedAchievementsInThisSet) {
        totalExpGainedFromThisSetAchievements += ach.expReward;
        print("Processando conquista: ${ach.description} - EXP: ${ach.expReward}");
      }
      print("Total EXP a ser adicionado: $totalExpGainedFromThisSetAchievements");

      try {
        // Buscar dados atuais do usuário
        DocumentSnapshot snapshot = await userDocRef.get();
        if (!snapshot.exists) {
          print("Documento do usuário não existe!");
          return;
        }
        
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>? ?? {};
        Map<String, dynamic> completedAchMap = Map<String, dynamic>.from(data['completedAchievements'] ?? {});
        List<String> unlockedTitlesList = List<String>.from(data['unlockedTitles'] ?? ['Aspirante']);
        
        // Processar conquistas
        for (var ach in newlyCompletedAchievementsInThisSet) {
          completedAchMap[ach.id] = true;
          if (ach.titleReward != null && !unlockedTitlesList.contains(ach.titleReward!)) {
            unlockedTitlesList.add(ach.titleReward!);
          }
        }
          
        double currentDbExp = (data['exp'] ?? 0.0).toDouble();
        double finalNewTotalExpForUserFromTransaction = currentDbExp + totalExpGainedFromThisSetAchievements;
        
        // Atualizar dados no Firestore
        print("Salvando conquistas no Firestore...");
        await userDocRef.update({
          'completedAchievements': completedAchMap,
          'exp': finalNewTotalExpForUserFromTransaction,
          'unlockedTitles': unlockedTitlesList,
        });
        print("Conquistas salvas com sucesso!");

        if (mounted) {
          setState(() {
            _currentPlayerExp = finalNewTotalExpForUserFromTransaction;
            for (var ach in newlyCompletedAchievementsInThisSet) {
              _completedAchievementsInSession.add(ach);
              _userCompletedAchievementsMap[ach.id] = true;
            }
          });

          for (var achievement in newlyCompletedAchievementsInThisSet) {
            await showStyledDialog(
              passedContext: context,
              titleText: "Conquista Desbloqueada!",
              icon: Icons.emoji_events_rounded,
              iconColor: achievementColor,
              contentWidgets: [
                Text(
                  "Você alcançou: \"${achievement.description}\"\n+${achievement.expReward} EXP!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: textColor, fontSize: 16)
                )
              ],
              actions: [
                buildDialogButton(context, "Ok", () => Navigator.of(context).pop(), true)
              ],
            );
            // Enviar notificação de amigo para a conquista (sem await para não bloquear)
            String friendNotificationMessage = 'desbloqueou a conquista "${achievement.description}"';
            if (achievement.titleReward != null) {
              friendNotificationMessage += ' e ganhou o título "${achievement.titleReward}"!';
            }
            _sendFriendNotification(friendNotificationMessage).catchError((e) {
              print("Erro ao enviar notificação de amigo: $e");
            });
            // Enviar notificação de guilda para a conquista/título (sem await para não bloquear)
            _sendGuildNotification(friendNotificationMessage).catchError((e) {
              print("Erro ao enviar notificação de guilda: $e");
            });
            if (achievement.titleReward != null && mounted) {
              await Future.delayed(const Duration(milliseconds: 300));
              if (!mounted) return;
              await showStyledDialog(
                passedContext: context,
                titleText: "Novo Título!",
                icon: Icons.military_tech_rounded,
                iconColor: prColor,
                contentWidgets: [
                  Text(
                    "Você desbloqueou o título:\n'${achievement.titleReward}'",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: textColor, fontSize: 16)
                  )
                ],
                actions: [
                  buildDialogButton(context, "Entendido", () => Navigator.of(context).pop(), true)
                ],
              );
            }
          }
          await _checkForLevelUpAfterExpGain();
        }
      } catch (e, s) {
        print("=== ERRO DETALHADO ===");
        print("Tipo do erro: ${e.runtimeType}");
        print("Mensagem: $e");
        print("Stack trace: $s");
        print("=====================");
        
        // Tentar salvar as conquistas de forma mais simples
        try {
          print("Tentando salvar conquistas de forma simplificada...");
          Map<String, dynamic> simpleUpdate = {};
          
          // Apenas marcar as conquistas como completas
          for (var ach in newlyCompletedAchievementsInThisSet) {
            simpleUpdate['completedAchievements.${ach.id}'] = true;
          }
          
          // Incrementar EXP de forma simples
          simpleUpdate['exp'] = FieldValue.increment(totalExpGainedFromThisSetAchievements);
          
          await userDocRef.update(simpleUpdate);
          print("Salvamento simplificado bem-sucedido!");
          
          // Atualizar estado local
          if (mounted) {
            setState(() {
              _currentPlayerExp += totalExpGainedFromThisSetAchievements;
              for (var ach in newlyCompletedAchievementsInThisSet) {
                _completedAchievementsInSession.add(ach);
                _userCompletedAchievementsMap[ach.id] = true;
              }
            });
          }
          
        } catch (e2) {
          print("Erro também no salvamento simplificado: $e2");
          if (mounted) {
            showStyledDialog(
              passedContext: context,
              titleText: "Erro",
              icon: Icons.error_outline,
              iconColor: Colors.redAccent,
              contentWidgets: [
                Text(
                  "Erro ao registrar conquista(s).",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: textColor, fontSize: 16)
                )
              ],
              actions: [
                buildDialogButton(context, "Ok", () => Navigator.of(context).pop(), true)
              ],
            );
          }
        }
      }
    }
  }

  Future<void> _checkForLevelUpAfterExpGain() async {
    if (!mounted) return;
    bool leveledUpThisCycle = false;
    int skillPointsGainedThisCycle = 0;
    bool needsSaveToFirestore = false;
    int expNeeded = getExpForNextLevel(_currentPlayerLevel);

    while (_currentPlayerExp >= expNeeded && expNeeded > 0) {
      needsSaveToFirestore = true;
      leveledUpThisCycle = true;
      _currentPlayerExp -= expNeeded;
      _currentPlayerLevel++;
      int pointsPerLevel = 3;
      _currentPlayerSkillPoints += pointsPerLevel;
      skillPointsGainedThisCycle += pointsPerLevel;
      expNeeded = getExpForNextLevel(_currentPlayerLevel);
      print("LEVEL UP (WorkoutScreen)! Novo Nível: $_currentPlayerLevel, XP Atual: $_currentPlayerExp, Próximo Nível: $expNeeded, Pontos Ganhos: $pointsPerLevel");
    }

    if (leveledUpThisCycle) {
      if (mounted) {
        setState(() {});
      }
      if (needsSaveToFirestore) {
        await _saveLevelUpDataToFirestore(_currentPlayerLevel, _currentPlayerExp, _currentPlayerSkillPoints);
      }
      if (mounted) {
        showStyledDialog(
          passedContext: context,
          titleText: "LEVEL UP!",
          icon: Icons.military_tech_rounded,
          iconColor: levelUpColor,
          contentWidgets: [
            Text(
              "Parabéns, $_currentPlayerName!",
              textAlign: TextAlign.center,
              style: const TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 10),
            Text(
              "Você alcançou o Nível $_currentPlayerLevel!",
              textAlign: TextAlign.center,
              style: const TextStyle(color: textColor, fontSize: 16)
            ),
            if (skillPointsGainedThisCycle > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Você ganhou +$skillPointsGainedThisCycle Pontos de Habilidade!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: greenStatColor, fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
          ],
          actions: [
            buildDialogButton(context, "INCRÍVEL!", () => Navigator.of(context).pop(), true)
          ],
        );
      }
    }
  }

  Future<void> _saveLevelUpDataToFirestore(int newLevel, double newExp, int newSkillPoints) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        // Obter o nível anterior atual do Firestore
        final currentData = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        int previousLevel = currentData.data()?['level'] ?? 1;
        
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'level': newLevel,
          'exp': newExp,
          'availableSkillPoints': newSkillPoints,
          'previousLevel': previousLevel,
        });
        print("Dados de Level Up (WorkoutScreen) salvos no Firebase.");
      } catch (e) {
        print("Erro ao salvar dados de level up (WorkoutScreen) no Firebase: $e");
      }
    }
  }

  void _startRestTimer() {
    if (!mounted) return;
    print("=== INICIANDO TIMER DE DESCANSO ===");
    print("_isResting antes: $_isResting");
    print("_defaultRestTimeSeconds: $_defaultRestTimeSeconds");
    setState(() {
      _isResting = true;
      _currentRestTimeLeft = _defaultRestTimeSeconds;
    });
    print("_isResting depois: $_isResting");
    print("_currentRestTimeLeft: $_currentRestTimeLeft");
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_currentRestTimeLeft > 0) {
          _currentRestTimeLeft--;
        } else {
          print("Timer de descanso finalizado, movendo para próxima série/exercício");
          timer.cancel();
          _moveToNextSetOrExercise();
        }
      });
    });
    print("Timer iniciado com sucesso");
  }

  int getExpForNextLevel(int currentLvl) {
    if (currentLvl <= 0) return 100;
    return (100 * pow(1.35, currentLvl - 1)).round();
  }

  // --- Nova função para enviar notificação para amigos ---
  Future<void> _sendFriendNotification(String message) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("Usuário não logado, não é possível enviar notificações para amigos.");
      return;
    }

    try {
      // Buscar nome do usuário atual
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) return;
      
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      String userName = userData?['playerName'] ?? "Um amigo";

      // Buscar IDs dos amigos
      QuerySnapshot friendsSnapshot = await FirebaseFirestore.instance
          .collection('users').doc(currentUser.uid).collection('friends').get();

      if (friendsSnapshot.docs.isEmpty) {
        print("Nenhum amigo encontrado.");
        return;
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var friendDoc in friendsSnapshot.docs) {
        String friendId = friendDoc.id;

        // Adicionar notificação na coleção notifications do amigo
        batch.set(FirebaseFirestore.instance.collection('notifications').doc(), {
          'userId': friendId,
          'type': 'friend',
          'message': '$userName $message',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print("Notificações de amigo enviadas com sucesso para ${friendsSnapshot.docs.length} amigos.");

    } catch (e) {
      print("Erro ao enviar notificação para amigos: $e");
      // Não propagar o erro para não afetar outras funcionalidades
    }
  }

  // --- Nova função para enviar notificação para membros da guilda ---
  Future<void> _sendGuildNotification(String message) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("Usuário não logado, não é possível enviar notificações para a guilda.");
      return;
    }

    try {
      // Buscar informações do usuário para obter guildId e nome
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) return;
      
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      String? guildId = userData?['guildId'];
      String userName = userData?['playerName'] ?? "Um membro";

      if (guildId == null || guildId.isEmpty) {
        print("Usuário não pertence a nenhuma guilda.");
        return;
      }

      // Buscar IDs dos membros da guilda
      QuerySnapshot membersSnapshot = await FirebaseFirestore.instance
          .collection('guilds').doc(guildId).collection('members').get();

      if (membersSnapshot.docs.isEmpty) {
        print("Nenhum membro encontrado na guilda.");
        return;
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();
      int notificationsSent = 0;

      for (var memberDoc in membersSnapshot.docs) {
        String memberId = memberDoc.id;

        // Não enviar notificação para o próprio usuário
        if (memberId != currentUser.uid) {
          batch.set(FirebaseFirestore.instance.collection('notifications').doc(), {
            'userId': memberId,
            'type': 'guild',
            'message': '$userName $message',
            'timestamp': FieldValue.serverTimestamp(),
          });
          notificationsSent++;
        }
      }

      if (notificationsSent > 0) {
        await batch.commit();
        print("Notificações de guilda enviadas com sucesso para $notificationsSent membros.");
      }

    } catch (e) {
      print("Erro ao enviar notificação para membros da guilda: $e");
      // Não propagar o erro para não afetar outras funcionalidades
    }
  }

  Widget _buildExerciseSelectionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Selecione o próximo exercício:",
            style: const TextStyle(color: accentColorBlue, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: widget.exercises.length,
            itemBuilder: (context, index) {
              final exercise = widget.exercises[index];
              final isCompleted = _completedExerciseIndices.contains(index);
              return Card(
                color: panelBgColor.withOpacity(isCompleted ? 0.5 : 0.8),
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isCompleted ? Colors.grey : accentColorBlue.withOpacity(0.7),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    exercise.exercise.name,
                    style: TextStyle(
                      color: isCompleted ? Colors.grey : textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    exercise.exercise.isTimeBased
                        ? "${exercise.sets}x ${exercise.durationMinutes ?? '-'} min"
                        : "${exercise.sets}x ${exercise.reps ?? '-'} ${exercise.lastWeight != null ? '- ${exercise.lastWeight!.toStringAsFixed(1)}kg' : ''}",
                    style: TextStyle(
                      color: isCompleted ? Colors.grey : textColor.withOpacity(0.7),
                    ),
                  ),
                  trailing: isCompleted
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.arrow_forward_ios, color: accentColorBlue),
                  onTap: isCompleted
                      ? null
                      : () {
                          setState(() {
                            _currentExerciseIndex = index;
                            _currentSetNumber = 1;
                            _isSelectingExercise = false;
                          });
                          _loadDataForCurrentExercise();
                        },
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildExerciseCard() {
    final exercise = widget.exercises[_currentExerciseIndex];
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _buildWorkoutView(exercise, exercise.exercise),
    );
  }

  Widget _buildWorkoutCompleteCard() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Treino Concluído!',
            style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Você completou todos os exercícios do treino ${widget.dayOfWeek}',
            style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: const Text("FINALIZAR SÉRIE"),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isResting ? Colors.grey : Colors.green.shade600,
            foregroundColor: textColor,
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: _isResting ? null : _finishSet,
        ),
      ),
    );
  }

  Widget _buildFinishWorkoutButton() {
    int totalExercises = widget.exercises.length;
    int completedExercises = _completedExerciseIndices.length;
    bool allCompleted = completedExercises == totalExercises;
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.flag_rounded),
          label: Text(allCompleted ? "FINALIZAR TREINO" : "FINALIZAR TREINO ($completedExercises/$totalExercises)"),
          style: ElevatedButton.styleFrom(
            backgroundColor: allCompleted ? Colors.green.shade600 : Colors.orange.shade600,
            foregroundColor: textColor,
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: _finishWorkout,
        ),
      ),
    );
  }

  Future<void> _finishWorkout() async {
    int totalExercises = widget.exercises.length;
    int completedExercises = _completedExerciseIndices.length;
    bool allCompleted = completedExercises == totalExercises;

    if (!allCompleted) {
      // Mostrar diálogo perguntando se quer finalizar mesmo com exercícios faltando
      final bool? shouldFinish = await showStyledDialog<bool>(
        passedContext: context,
        titleText: "Finalizar Treino Incompleto?",
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.orange,
        contentWidgets: [
          Text(
            "Você completou $completedExercises de $totalExercises exercícios.\n\nDeseja finalizar o treino mesmo assim?",
            textAlign: TextAlign.center,
            style: const TextStyle(color: textColor, fontSize: 16),
          ),
        ],
        actions: [
          buildDialogButton(context, "Continuar Treino", () => Navigator.of(context).pop(false), false),
          buildDialogButton(context, "Finalizar", () => Navigator.of(context).pop(true), true),
        ],
      );

      if (shouldFinish != true) {
        return; // Usuário escolheu continuar o treino
      }
    }

    // Finalizar o treino
    _showWorkoutCompleteDialog();
  }
}

// --- TELA PRINCIPAL DE TREINOS ---
class TreinoScreen extends StatefulWidget {
  const TreinoScreen({super.key});
  @override
  State<TreinoScreen> createState() => _TreinoScreenState();
}

class _TreinoScreenState extends State<TreinoScreen> {
  final List<String> _daysOfWeek = [
    "Segunda-feira", 
    "Terça-feira", 
    "Quarta-feira", 
    "Quinta-feira", 
    "Sexta-feira", 
    "Sábado", 
    "Domingo"
  ];
  String _selectedDay = "Segunda-feira"; // Corrigido para 'Segunda-feira'
  bool _isWorkoutInProgress = false;
  String? _inProgressDay;
  final SettingsService _settingsService = SettingsService();
  int _restTime = 60; // Valor padrão, será atualizado ao carregar as configurações

  // Helper para tradução
  String _t(String key) {
    final languageService = context.read<LanguageService>();
    return TranslationService.get(key, languageService.currentLanguageCode);
  }

  List<String> get _translatedDaysOfWeek => [
    _t('monday'),
    _t('tuesday'), 
    _t('wednesday'),
    _t('thursday'),
    _t('friday'),
    _t('saturday'),
    _t('sunday')
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkForInProgressWorkout();
    // Aguardar o frame seguinte para ter acesso ao context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selectedDay = _translatedDaysOfWeek[0]; // Segunda-feira
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadSettings() async {
    _restTime = await _settingsService.getRestTime();
    if (mounted) setState(() {});
  }

  Future<void> _checkForInProgressWorkout() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _isWorkoutInProgress = data['inProgressWorkout'] ?? false;
              _inProgressDay = data['inProgressWorkoutDay'];
            });
          }
        }
      } catch (e) {
        print("Erro ao verificar treino em progresso: $e");
      }
    }
  }

  Future<void> _updateWorkoutProgressStatus(bool inProgress, String? day) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'inProgressWorkout': inProgress,
          'inProgressWorkoutDay': day,
        });
        if (mounted) {
          setState(() {
            _isWorkoutInProgress = inProgress;
            _inProgressDay = day;
          });
        }
      } catch (e) {
        print("Erro ao atualizar status do treino: $e");
      }
    }
  }

  Future<void> _showWorkoutPlanningDialog({PlannedExercise? initialExercise}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseSelectionScreen(
          dayOfWeek: _selectedDay,
          onSavePlan: (List<PlannedExercise> selectedExercises) async {
            if (!mounted) return;
            await _saveWorkoutPlanToFirestore(_selectedDay, selectedExercises);
            setState(() {});
          },
          existingExercises: initialExercise != null ? [initialExercise] : [],
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {});
    }
  }

  Future<void> _saveWorkoutPlanToFirestore(String day, List<PlannedExercise> exercises) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('workoutPlans')
            .doc(day)
            .set({
          'exercises': exercises.map((e) => e.toMap()).toList(),
        });
        
        if (mounted) {
          showStyledDialog(
            passedContext: context,
            titleText: "Sucesso",
            icon: Icons.check_circle_rounded,
            iconColor: Colors.green,
            contentWidgets: [
              Text(
                "Treino salvo com sucesso!",
                textAlign: TextAlign.center,
                style: const TextStyle(color: textColor, fontSize: 16),
              ),
            ],
            actions: [
              buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
            ],
          );
        }
      } catch (e) {
        print("Erro ao salvar plano de treino: $e");
        if (mounted) {
          showStyledDialog(
            passedContext: context,
            titleText: "Erro",
            icon: Icons.error_outline,
            iconColor: Colors.redAccent,
            contentWidgets: [
              Text(
                "Erro ao salvar treino. Tente novamente.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: textColor, fontSize: 16),
              ),
            ],
            actions: [
              buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
            ],
          );
        }
      }
    }
  }

  void _onDaySelected(String day) {
    if (!mounted) return;
    setState(() {
      _selectedDay = day;
    });
  }

  Widget _buildPlannedWorkoutDetails() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('workoutPlans')
          .doc(_selectedDay)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: accentColorPurple));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Nenhum treino planejado para $_selectedDay",
                  style: const TextStyle(color: textColor, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text("PLANEJAR TREINO"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColorBlue,
                    foregroundColor: textColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _showWorkoutPlanningDialog(),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final List<dynamic> exercisesData = data['exercises'] ?? [];
        final List<PlannedExercise> plannedExercises = exercisesData
            .map((e) => PlannedExercise.fromMap(e as Map<String, dynamic>))
            .toList();

        if (plannedExercises.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Nenhum treino planejado para $_selectedDay",
                  style: const TextStyle(color: textColor, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text("PLANEJAR TREINO"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColorBlue,
                    foregroundColor: textColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _showWorkoutPlanningDialog(),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: plannedExercises.length,
                itemBuilder: (context, index) {
                  final exercise = plannedExercises[index];
                  return Card(
                    color: panelBgColor.withOpacity(0.8),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: accentColorBlue.withOpacity(0.7),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        exercise.exercise.name,
                        style: const TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        exercise.exercise.isTimeBased
                            ? "${exercise.sets}x ${exercise.durationMinutes ?? '-'} min"
                            : "${exercise.sets}x ${exercise.reps ?? '-'} ${exercise.lastWeight != null ? '- ${exercise.lastWeight!.toStringAsFixed(1)}kg' : ''}",
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isWorkoutInProgress && _inProgressDay == _selectedDay
                  ? ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text("RETOMAR TREINO"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: textColor,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkoutExecutionScreen(
                              dayOfWeek: _selectedDay,
                              exercises: plannedExercises,
                              isResuming: true,
                              restTime: _restTime,
                            ),
                          ),
                        ).then((_) => _checkForInProgressWorkout());
                      },
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                         Expanded(
                           child: ElevatedButton.icon(
                             icon: const Icon(Icons.edit_note_rounded),
                             label: const Text("EDITAR PLANO"),
                             style: ElevatedButton.styleFrom(
                               backgroundColor: accentColorBlue,
                               foregroundColor: textColor,
                               padding: const EdgeInsets.symmetric(vertical: 15),
                               textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                             ),
                             onPressed: () {
                               Navigator.push(
                                 context,
                                 MaterialPageRoute(
                                   builder: (context) => ExerciseSelectionScreen(
                                     dayOfWeek: _selectedDay,
                                     onSavePlan: (List<PlannedExercise> selectedExercises) async {
                                       if (!mounted) return;
                                       await _saveWorkoutPlanToFirestore(_selectedDay, selectedExercises);
                                       setState(() {});
                                     },
                                     existingExercises: plannedExercises,
                                   ),
                                 ),
                               ).then((_) => _checkForInProgressWorkout());
                             },
                           ),
                         ),
                         SizedBox(width: 16),
                         Expanded(
                           child: ElevatedButton.icon(
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text("INICIAR TREINO"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: textColor,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              onPressed: plannedExercises.isEmpty ? null : () {
                                _updateWorkoutProgressStatus(true, _selectedDay);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WorkoutExecutionScreen(
                                      dayOfWeek: _selectedDay,
                                      exercises: plannedExercises,
                                      restTime: _restTime,
                                    ),
                                  ),
                                ).then((_) => _checkForInProgressWorkout());
                              },
                            ),
                         ),
                      ],
                   ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( backgroundColor: primaryColor,
      appBar: AppBar( automaticallyImplyLeading: false, title: const Text("Meus Treinos Semanais", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,),
      body: Column( children: [
        SizedBox( height: 70,
          child: ListView.builder( padding: const EdgeInsets.symmetric(vertical:10, horizontal: 5), scrollDirection: Axis.horizontal, itemCount: _daysOfWeek.length,
            itemBuilder: (context, index) {
              final day = _daysOfWeek[index];
              bool isSelected = day == _selectedDay;
              return Padding( padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ElevatedButton(
                  onPressed: () => _onDaySelected(day),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? accentColorPurple : panelBgColor,
                    foregroundColor: textColor,
                    shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? accentColorBlue : panelBgColor.withOpacity(0.5), width: 1.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 12)
                  ),
                  child: Text(day.substring(0,3).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
        ),
        Divider(color: accentColorBlue.withOpacity(0.5), height: 1, thickness: 1),
        Expanded( child: _buildPlannedWorkoutDetails()),
      ],
    ),
  );
  }
}