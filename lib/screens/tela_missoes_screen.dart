// Em lib/screens/tela_missoes_screen.dart
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_build_context_synchronously, avoid_print, constant_identifier_names, deprecated_member_use, unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart' show notifyDailyMissionsChanged;
// import 'dart:math'; // REMOVIDO - Unused import

// CORES (Definidas aqui para o exemplo, idealmente de um arquivo global)
const Color primaryColor = Color(0xFF0A0E21);
const Color accentColorBlue = Color(0xFF40C4FF);
const Color accentColorPurple = Color(0xFF8A2BE2);
const Color textColor = Colors.white;
const Color panelBgColor = Color(0x991D1E33);
const Color yellowWarningColor = Colors.yellowAccent;

// Helper para converter enum em string legível (PARA DISPLAY)
String statAttributeToString(StatAttribute attribute) {
  switch (attribute) {
    case StatAttribute.FOR: return "Força";
    case StatAttribute.VIT: return "Vitalidade";
    case StatAttribute.AGI: return "Agilidade";
    case StatAttribute.INT: return "Inteligência";
    case StatAttribute.PER: return "Percepção";
    case StatAttribute.NONE: return "Nenhuma";
  }
}

// Helper para mapear ícones por atributo (igual da profile screen)
IconData getIconForAttribute(StatAttribute attribute) {
  switch (attribute) {
    case StatAttribute.FOR: return Icons.fitness_center;
    case StatAttribute.VIT: return Icons.favorite;
    case StatAttribute.AGI: return Icons.directions_run;
    case StatAttribute.INT: return Icons.psychology;
    case StatAttribute.PER: return Icons.visibility;
    case StatAttribute.NONE: return Icons.help_outline;
  }
}

// --- MODELOS DE DADOS PARA MISSÕES ---
enum StatAttribute { FOR, VIT, AGI, INT, PER, NONE }

class Mission {
  final String id;
  final String title;
  final String description;
  final StatAttribute rewardAttribute;
  final int rewardAmount;
  final bool isDefaultDaily;

  Mission({
    required this.id,
    required this.title,
    this.description = "",
    required this.rewardAttribute,
    this.rewardAmount = 1,
    this.isDefaultDaily = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'rewardAttribute': rewardAttribute.name,
      'rewardAmount': rewardAmount,
      'isDefaultDaily': isDefaultDaily,
    };
  }

  factory Mission.fromMap(Map<String, dynamic> map) {
    return Mission(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? "",
      rewardAttribute: StatAttribute.values.firstWhere(
        (e) => e.name == map['rewardAttribute'],
        orElse: () => StatAttribute.NONE,
      ),
      rewardAmount: map['rewardAmount'] ?? 1,
      isDefaultDaily: map['isDefaultDaily'] ?? false,
    );
  }
}

// LISTA MESTRA DE MISSÕES DISPONÍVEIS
final List<Mission> allAvailableMissions = [
  // Missões de Força
  Mission(id: 'daily_squats_100', title: "100 Agachamentos", description: "Fortaleça suas pernas e core.", rewardAttribute: StatAttribute.FOR, rewardAmount: 1, isDefaultDaily: true),
  Mission(id: 'daily_pushups_100', title: "100 Flexões", description: "Desenvolva força no peitoral, ombros e tríceps.", rewardAttribute: StatAttribute.FOR, rewardAmount: 1, isDefaultDaily: true),
  Mission(id: 'train_today', title: "Treinar Conforme Planejado", description: "Siga seu plano de treino do dia.", rewardAttribute: StatAttribute.FOR, rewardAmount: 2),
  Mission(id: 'lift_heavy_today', title: "Levantar Peso Pesado", description: "Faça pelo menos 1 exercício com 80%+ do seu máximo.", rewardAttribute: StatAttribute.FOR, rewardAmount: 2),
  Mission(id: 'daily_pullups_20', title: "20 Barras Fixas", description: "Desenvolva força nas costas e bíceps.", rewardAttribute: StatAttribute.FOR, rewardAmount: 1),
  Mission(id: 'daily_dips_30', title: "30 Paralelas", description: "Fortaleça tríceps e peito.", rewardAttribute: StatAttribute.FOR, rewardAmount: 1),
  Mission(id: 'carry_heavy_objects', title: "Carregar Objetos Pesados", description: "Transporte algo pesado por pelo menos 50 metros.", rewardAttribute: StatAttribute.FOR, rewardAmount: 1),

  // Missões de Vitalidade
  Mission(id: 'daily_situps_100', title: "100 Abdominais", description: "Defina seu core.", rewardAttribute: StatAttribute.VIT, rewardAmount: 1, isDefaultDaily: true),
  Mission(id: 'drink_water_2l', title: "Beber 2L de Água", description: "Hidratação é chave para a performance.", rewardAttribute: StatAttribute.VIT, rewardAmount: 1),
  Mission(id: 'no_sugar_today', title: "Dia Sem Açúcar Refinado", description: "Escolhas saudáveis fortalecem o corpo.", rewardAttribute: StatAttribute.VIT, rewardAmount: 1),
  Mission(id: 'eat_5_fruits_veggies', title: "Comer 5 Frutas/Vegetais", description: "Nutrição de qualidade fortalece o corpo.", rewardAttribute: StatAttribute.VIT, rewardAmount: 1),
  Mission(id: 'sleep_8_hours', title: "Dormir 8 Horas", description: "Recuperação adequada é essencial.", rewardAttribute: StatAttribute.VIT, rewardAmount: 1),
  Mission(id: 'daily_plank_5min', title: "Prancha por 5 Minutos", description: "Resistência do core.", rewardAttribute: StatAttribute.VIT, rewardAmount: 2),
  Mission(id: 'no_junk_food', title: "Dia Sem Comida Processada", description: "Alimente seu corpo com qualidade.", rewardAttribute: StatAttribute.VIT, rewardAmount: 1),
  Mission(id: 'take_vitamins', title: "Tomar Vitaminas/Suplementos", description: "Apoie sua saúde com nutrientes.", rewardAttribute: StatAttribute.VIT, rewardAmount: 1),

  // Missões de Agilidade
  Mission(id: 'daily_run_10km', title: "Correr 10km", description: "Aumente sua resistência.", rewardAttribute: StatAttribute.AGI, rewardAmount: 1, isDefaultDaily: true),
  Mission(id: 'walk_30min', title: "Caminhar por 30 Minutos", description: "Mantenha o corpo ativo.", rewardAttribute: StatAttribute.AGI, rewardAmount: 1),
  Mission(id: 'daily_run_5km', title: "Correr 5km", description: "Cardio moderado para resistência.", rewardAttribute: StatAttribute.AGI, rewardAmount: 1),
  Mission(id: 'bike_30min', title: "Pedalar por 30 Minutos", description: "Cardio de baixo impacto.", rewardAttribute: StatAttribute.AGI, rewardAmount: 1),
  Mission(id: 'stairs_10_floors', title: "Subir 10 Andares de Escada", description: "Use as pernas em vez do elevador.", rewardAttribute: StatAttribute.AGI, rewardAmount: 1),
  Mission(id: 'dance_20min', title: "Dançar por 20 Minutos", description: "Diversão e movimento.", rewardAttribute: StatAttribute.AGI, rewardAmount: 1),
  Mission(id: 'swim_30min', title: "Nadar por 30 Minutos", description: "Exercício completo de baixo impacto.", rewardAttribute: StatAttribute.AGI, rewardAmount: 2),
  Mission(id: 'hiit_workout_15min', title: "HIIT por 15 Minutos", description: "Treino intervalado de alta intensidade.", rewardAttribute: StatAttribute.AGI, rewardAmount: 2),

  // Missões de Inteligência
  Mission(id: 'read_pages_10', title: "Ler 10 Páginas de um Livro", description: "Conhecimento também é poder.", rewardAttribute: StatAttribute.INT, rewardAmount: 1),
  Mission(id: 'meditate_10min', title: "Meditar por 10 Minutos", description: "Clareza mental para os desafios.", rewardAttribute: StatAttribute.INT, rewardAmount: 1),
  Mission(id: 'learn_new_skill_15min', title: "Praticar Nova Habilidade por 15 min", description: "Sempre evoluindo.", rewardAttribute: StatAttribute.INT, rewardAmount: 2),
  Mission(id: 'solve_puzzle', title: "Resolver um Quebra-Cabeça", description: "Exercite sua mente.", rewardAttribute: StatAttribute.INT, rewardAmount: 1),
  Mission(id: 'watch_educational_video', title: "Assistir Vídeo Educativo", description: "Aprenda algo novo hoje.", rewardAttribute: StatAttribute.INT, rewardAmount: 1),
  Mission(id: 'practice_language_20min', title: "Praticar Idioma por 20 min", description: "Expanda suas habilidades linguísticas.", rewardAttribute: StatAttribute.INT, rewardAmount: 1),
  Mission(id: 'write_journal_entry', title: "Escrever no Diário", description: "Reflexão e autoconhecimento.", rewardAttribute: StatAttribute.INT, rewardAmount: 1),
  Mission(id: 'research_topic_30min', title: "Pesquisar Tópico por 30 min", description: "Aprofunde-se em algo interessante.", rewardAttribute: StatAttribute.INT, rewardAmount: 2),

  // Missões de Percepção
  Mission(id: 'make_bed', title: "Arrumar a Cama", description: "Comece o dia com disciplina.", rewardAttribute: StatAttribute.PER, rewardAmount: 1),
  Mission(id: 'wake_up_early_6am', title: "Acordar às 6h", description: "Aproveite a manhã produtiva.", rewardAttribute: StatAttribute.PER, rewardAmount: 1),
  Mission(id: 'plan_tomorrow', title: "Planejar o Dia Seguinte", description: "Organização leva à vitória.", rewardAttribute: StatAttribute.PER, rewardAmount: 1),
  Mission(id: 'clean_living_space', title: "Limpar Espaço de Convivência", description: "Ambiente organizado, mente clara.", rewardAttribute: StatAttribute.PER, rewardAmount: 1),
  Mission(id: 'practice_mindfulness', title: "Praticar Mindfulness", description: "Esteja presente no momento.", rewardAttribute: StatAttribute.PER, rewardAmount: 1),
  Mission(id: 'observe_nature_15min', title: "Observar a Natureza por 15 min", description: "Conecte-se com o ambiente.", rewardAttribute: StatAttribute.PER, rewardAmount: 1),
  Mission(id: 'practice_gratitude', title: "Praticar Gratidão", description: "Liste 3 coisas pelas quais é grato.", rewardAttribute: StatAttribute.PER, rewardAmount: 1),
  Mission(id: 'digital_detox_2hours', title: "Detox Digital por 2 Horas", description: "Desconecte-se das telas.", rewardAttribute: StatAttribute.PER, rewardAmount: 2),
  Mission(id: 'help_someone', title: "Ajudar Alguém", description: "Faça uma boa ação hoje.", rewardAttribute: StatAttribute.PER, rewardAmount: 1),
];

class TelaMissoesScreen extends StatefulWidget {
  const TelaMissoesScreen({super.key});

  @override
  State<TelaMissoesScreen> createState() => _TelaMissoesScreenState();
}

class _TelaMissoesScreenState extends State<TelaMissoesScreen> {
  List<String> _selectedDailyQuestIds = [];
  bool _isLoading = true;
  final int _maxDailyQuests = 5;
  List<String> _initialSelectedDailyQuestIds = []; // Para rastrear mudanças
  bool _hasChanges = false; // Para controlar se há mudanças não salvas

  StatAttribute? _selectedAttributeFilter;
  List<Mission> _filteredAvailableMissions = [];

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
                Expanded(
                  child: Text(
                    titleText,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          content: contentWidgets.isNotEmpty 
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: contentWidgets,
              )
            : null,
          actions: actions,
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserSelectedMissions();
  }

  void _updateFilteredMissions() {
    List<Mission> available = allAvailableMissions.where((mission) {
      return !_selectedDailyQuestIds.contains(mission.id);
    }).toList();

    if (_selectedAttributeFilter != null && _selectedAttributeFilter != StatAttribute.NONE) {
      available = available.where((mission) => mission.rewardAttribute == _selectedAttributeFilter).toList();
    }

    setState(() {
      _filteredAvailableMissions = available;
    });
  }

  Future<void> _loadUserSelectedMissions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("Nenhum usuário logado para carregar missões.");
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

      List<String> userDailyMissionIds = [];
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('selectedDailyQuestIds') && data['selectedDailyQuestIds'] is List) {
          userDailyMissionIds = List<String>.from(data['selectedDailyQuestIds']);
        }
      }

      // Se o usuário não tem missões selecionadas, usar as padrão
      if (userDailyMissionIds.isEmpty) {
        userDailyMissionIds = allAvailableMissions
            .where((mission) => mission.isDefaultDaily)
            .map((mission) => mission.id)
            .take(_maxDailyQuests)
            .toList();
      }

      if (mounted) {
        setState(() {
          _selectedDailyQuestIds = userDailyMissionIds;
          _initialSelectedDailyQuestIds = List.from(userDailyMissionIds);
          _hasChanges = false;
          _isLoading = false;
        });
        _updateFilteredMissions();
      }
    } catch (e) {
      print("Erro ao carregar missões diárias do usuário: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveUserSelectedMissions() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("Usuário não logado. Não é possível salvar missões.");
      return;
    }

    if (!_hasChanges) {
      _showStyledDialog(
        passedContext: context,
        titleText: "Atenção",
        contentWidgets: [
          Text(
            "Não há alterações para serem salvas.",
            style: TextStyle(color: textColor, fontSize: 16),
          )
        ],
        actions: [
          _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
        ],
        icon: Icons.info_outline,
        iconColor: yellowWarningColor,
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'selectedDailyQuestIds': _selectedDailyQuestIds,
      });

      if (mounted) {
        setState(() {
          _initialSelectedDailyQuestIds = List.from(_selectedDailyQuestIds);
          _hasChanges = false;
        });

        _showStyledDialog(
          passedContext: context,
          titleText: "Sucesso",
          contentWidgets: [
            Text(
              "Suas missões diárias foram atualizadas!",
              style: TextStyle(color: textColor, fontSize: 16),
            )
          ],
          actions: [
            _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
          ],
          icon: Icons.check_circle_outline,
          iconColor: Colors.greenAccent,
        );
      }

      if (kDebugMode) {
        print("Missões diárias atualizadas com sucesso: $_selectedDailyQuestIds");
      }

      // Notificar a home screen sobre a mudança
      notifyDailyMissionsChanged();
    } catch (e) {
      print("Erro ao atualizar missões diárias: $e");
      if (mounted) {
        _showStyledDialog(
          passedContext: context,
          titleText: "Erro",
          contentWidgets: [
            Text(
              "Erro ao atualizar suas missões diárias.",
              style: TextStyle(color: textColor, fontSize: 16),
            )
          ],
          actions: [
            _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
          ],
          icon: Icons.error_outline,
          iconColor: Colors.redAccent,
        );
      }
    }
  }

  void _addMission(String missionId) {
    if (_selectedDailyQuestIds.length >= _maxDailyQuests) {
      _showStyledDialog(
        passedContext: context,
        titleText: "Limite Alcançado",
        contentWidgets: [
          Text(
            "Você pode selecionar no máximo $_maxDailyQuests missões diárias.",
            style: TextStyle(color: textColor, fontSize: 16),
          )
        ],
        actions: [
          _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
        ],
        icon: Icons.warning_amber_outlined,
        iconColor: yellowWarningColor,
      );
      return;
    }

    setState(() {
      _selectedDailyQuestIds.add(missionId);
      _hasChanges = !_listsEqual(_selectedDailyQuestIds, _initialSelectedDailyQuestIds);
    });
    _updateFilteredMissions();
  }

  void _removeMission(String missionId) {
    setState(() {
      _selectedDailyQuestIds.remove(missionId);
      _hasChanges = !_listsEqual(_selectedDailyQuestIds, _initialSelectedDailyQuestIds);
    });
    _updateFilteredMissions();
  }

  bool _listsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (!list2.contains(list1[i])) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: accentColorPurple))
          : CustomScrollView(
              slivers: [
                // Header - Título da tela
                SliverAppBar(
                  backgroundColor: primaryColor,
                  surfaceTintColor: primaryColor,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  floating: false,
                  pinned: true,
                  title: Text(
                    "MISSÕES",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  centerTitle: true,
                ),

                // Seção: Minhas Missões Diárias
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: panelBgColor,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: accentColorBlue, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.assignment_turned_in, color: accentColorBlue, size: 28),
                            const SizedBox(width: 10),
                            Text(
                              "Minhas Missões Diárias",
                              style: TextStyle(
                                color: textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        
                        _selectedDailyQuestIds.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inbox_outlined, color: Colors.grey.shade500, size: 50),
                                    const SizedBox(height: 10),
                                    Text(
                                      "Nenhuma missão diária selecionada.\nEscolha até $_maxDailyQuests missões abaixo!",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: _selectedDailyQuestIds.map((missionId) {
                                  Mission? mission = allAvailableMissions
                                      .where((m) => m.id == missionId)
                                      .firstOrNull;
                                  
                                  if (mission == null) {
                                    return ListTile(
                                      leading: Icon(Icons.error, color: Colors.redAccent),
                                      title: Text(
                                        "Missão Desconhecida (ID: $missionId)",
                                        style: TextStyle(color: Colors.redAccent),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete, color: Colors.redAccent),
                                        onPressed: () => _removeMission(missionId),
                                      ),
                                    );
                                  } else {
                                    return Card(
                                      color: panelBgColor.withOpacity(0.7),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.0),
                                        side: BorderSide(color: accentColorPurple.withOpacity(0.5)),
                                      ),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: accentColorPurple,
                                          child: Icon(
                                            getIconForAttribute(mission.rewardAttribute),
                                            color: textColor,
                                            size: 20,
                                          ),
                                        ),
                                        title: Text(
                                          mission.title,
                                          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                                        ),
                                        subtitle: Text(
                                          "${mission.description}\n+${mission.rewardAmount} ${statAttributeToString(mission.rewardAttribute)}",
                                          style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 12),
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(Icons.remove_circle, color: Colors.redAccent),
                                          onPressed: () => _removeMission(missionId),
                                        ),
                                      ),
                                    );
                                  }
                                }).toList(),
                              ),

                        // Botão Salvar Alterações
                        if (_hasChanges) ...[
                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _saveUserSelectedMissions,
                              icon: Icon(Icons.save, color: textColor),
                              label: Text("SALVAR ALTERAÇÕES", style: TextStyle(color: textColor)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColorPurple,
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  side: BorderSide(color: accentColorBlue),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Seção: Missões Disponíveis (com filtro e lista unificados)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: panelBgColor,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: accentColorBlue, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título da seção
                        Row(
                          children: [
                            Icon(Icons.assignment_outlined, color: accentColorBlue, size: 28),
                            const SizedBox(width: 10),
                            Text(
                              "Missões Disponíveis",
                              style: TextStyle(
                                color: textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // Filtro por Atributo
                        Row(
                          children: [
                            Text(
                              "Filtrar Atributo:",
                              style: TextStyle(color: textColor, fontSize: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButton<StatAttribute?>(
                                value: _selectedAttributeFilter,
                                dropdownColor: primaryColor,
                                style: TextStyle(color: textColor),
                                underline: Container(height: 1, color: accentColorBlue),
                                items: [
                                  DropdownMenuItem<StatAttribute?>(
                                    value: null,
                                    child: Text("Todos Atributos", style: TextStyle(color: textColor)),
                                  ),
                                  ...StatAttribute.values.where((attr) => attr != StatAttribute.NONE).map((attr) {
                                    return DropdownMenuItem<StatAttribute?>(
                                      value: attr,
                                      child: Text(statAttributeToString(attr), style: TextStyle(color: textColor)),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (StatAttribute? newValue) {
                                  setState(() {
                                    _selectedAttributeFilter = newValue;
                                  });
                                  _updateFilteredMissions();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // Lista de missões ou mensagem vazia
                        _filteredAvailableMissions.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.search_off, color: Colors.grey.shade500, size: 50),
                                      const SizedBox(height: 10),
                                      Text(
                                        "Nenhuma missão encontrada para este filtro ou todas já foram\nselecionadas como diárias.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Column(
                                children: _filteredAvailableMissions.map((mission) {
                                  return Card(
                                    color: panelBgColor.withOpacity(0.7),
                                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      side: BorderSide(color: accentColorBlue.withOpacity(0.5)),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: accentColorBlue,
                                        child: Icon(
                                          getIconForAttribute(mission.rewardAttribute),
                                          color: textColor,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        mission.title,
                                        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text(
                                        "${mission.description}\n+${mission.rewardAmount} ${statAttributeToString(mission.rewardAttribute)}",
                                        style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 12),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.add_circle, color: Colors.greenAccent),
                                        onPressed: () => _addMission(mission.id),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ],
                    ),
                  ),
                ),

                // Espaçamento inferior para evitar sobreposição com navigation bar
                SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
    );
  }
}