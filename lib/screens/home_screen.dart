// ignore_for_file: avoid_print, deprecated_member_use, unnecessary_brace_in_string_interps, prefer_const_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'package:gym_leveling/screens/ranking_screen.dart';
// Ensure this path and all exports are correct, especially TelaMissoesScreen
import 'package:gym_leveling/screens/tela_missoes_screen.dart' show StatAttribute, Mission, statAttributeToString, TelaMissoesScreen;
import 'dart:math'; // Para pow() em getExpForNextLevel
import 'dart:async'; // Para StreamSubscription
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../services/translation_service.dart';

import 'profile_screen.dart'; // Importa a tela de Perfil
import 'conquistas_screen.dart'; // Importa a tela de Conquistas
import 'treino_screen.dart'; // Importa a tela de Treino
import 'social_screen.dart'; // Importa a tela Social
import 'item_roulette_screen.dart';
import 'settings_screen.dart';
import 'package:gym_leveling/services/settings_service.dart';
import '../utils/aura_calculator.dart' as aura_utils;


// --- CORES GLOBAIS (Para fácil acesso) ---
const Color primaryColor = Color(0xFF0A0E21);
const Color accentColorBlue = Color(0xFF40C4FF);
const Color accentColorPurple = Color(0xFF8A2BE2);
const Color textColor = Colors.white;
const Color bottomNavBgColor = Color(0xFF1D1E33);
const Color panelBgColor = Color(0x991D1E33);
const Color greenStatColor = Colors.greenAccent;
const Color yellowWarningColor = Colors.yellowAccent;
const Color levelUpColor = Colors.amberAccent;
const Color achievementColor = Colors.amberAccent;
const Color prColor = Colors.amberAccent;

// --- CALLBACK GLOBAL PARA ATUALIZAÇÃO DE MISSÕES ---
typedef MissionUpdateCallback = void Function();
MissionUpdateCallback? _globalMissionUpdateCallback;

// Função global para notificar mudanças nas missões
void notifyDailyMissionsChanged() {
  if (_globalMissionUpdateCallback != null) {
    _globalMissionUpdateCallback!();
  }
} 

// --- Widget para Notificações Recentes ---
class RecentNotificationsPanel extends StatefulWidget {
  final String userId;
  const RecentNotificationsPanel({required this.userId, super.key});

  @override
  State<RecentNotificationsPanel> createState() => _RecentNotificationsPanelState();
}

class _RecentNotificationsPanelState extends State<RecentNotificationsPanel> with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _notifications = [];
  final List<Map<String, dynamic>> _tempNotifications = [];
  late AnimationController _animationController;
  bool _isExpanded = false;
  StreamSubscription? _notificationsSubscription;
  final SettingsService _settingsService = SettingsService();
  bool _showGlobalNotifications = true;
  bool _showGuildNotifications = true;
  bool _showFriendNotifications = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadSettings();
    _loadNotifications();
    _startTempNotifications();
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (_notificationsSubscription != null) { // Verifica se a inscrição existe
      _notificationsSubscription!.cancel(); // Cancela a inscrição do Firestore
    }
    super.dispose();
  }

  Future<void> _loadSettings() async {
    _showGlobalNotifications = await _settingsService.getShowGlobalNotifications();
    _showGuildNotifications = await _settingsService.getShowGuildNotifications();
    _showFriendNotifications = await _settingsService.getShowFriendNotifications();
    if (mounted) setState(() {});
  }

  List<Map<String, dynamic>> _filterNotifications(List<Map<String, dynamic>> notifications) {
    return notifications.where((notification) {
      switch (notification['type']) {
        case 'global':
          return _showGlobalNotifications;
        case 'guild':
          return _showGuildNotifications;
        case 'friend':
          return _showFriendNotifications;
        default:
          return true;
      }
    }).toList();
  }

  void _startTempNotifications() {
    // Simula recebimento de notificações temporárias
    // Future.delayed(const Duration(seconds: 2), () {
    //   if (mounted) {
    //     _addTempNotification({
    //       'type': 'global',
    //       'message': 'Gabriel roubou o 3 lugar de Rafaela em AURA!',
    //     });
    //   }
    // });

    // Future.delayed(const Duration(seconds: 4), () {
    //   if (mounted) {
    //     _addTempNotification({
    //       'type': 'friend',
    //       'message': 'Gabriel atingiu 100 kilos no SUPINO RETO BARRA!',
    //     });
    //   }
    // });

    // Future.delayed(const Duration(seconds: 6), () {
    //   if (mounted) {
    //     _addTempNotification({
    //       'type': 'guild',
    //       'message': 'Sua guilda completou o desafio semanal!',
    //     });
    //   }
    // });
  }


  Future<void> _loadNotifications() async {
    // Buscar notificações permanentes (histórico)
    if (widget.userId.isEmpty) {
      setState(() {
        _notifications.clear();
        _notifications.addAll([
          {
            'type': 'global',
            'message': 'Gabriel roubou o 3 lugar de Rafaela em AURA!',
            'timestamp': DateTime.now().subtract(const Duration(minutes: 2)),
          },
          {
            'type': 'friend',
            'message': 'Gabriel atingiu 100 kilos no SUPINO RETO BARRA 100KG!',
            'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
          },
          {
            'type': 'guild',
            'message': 'Sua guilda completou o desafio semanal!',
            'timestamp': DateTime.now().subtract(const Duration(minutes: 10)),
          },
           {
            'type': 'global',
            'message': 'Rafaela roubou o 5 lugar de Lucas em INTELIGÊNCIA!',
            'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
          },
          {
            'type': 'friend',
            'message': 'Gabriel obteve o item SSS COLAR DO MONARCA!',
            'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          },
          {
            'type': 'friend',
            'message': 'Gabriel obteve o título "AQUELE QUE LEVANTOU O MUNDO"!',
            'timestamp': DateTime.now().subtract(const Duration(hours: 3)),
          },
        ]);
      });
    }
  }

  Widget _buildTempNotificationItem(Map<String, dynamic> notification) {
    IconData icon;
    Color color;

    switch (notification['type']) {
      case 'global':
        icon = Icons.leaderboard_rounded;
        color = accentColorBlue;
        break;
      case 'friend':
        icon = Icons.person_rounded;
        color = greenStatColor;
        break;
      case 'guild':
        icon = Icons.group_rounded;
        color = accentColorPurple;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = textColor;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: 0.0),
      duration: const Duration(seconds: 5),
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: panelBgColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: color.withOpacity(0.6), width: 1.0),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  notification['message'],
                  style: TextStyle(color: textColor, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 60,
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    IconData icon;
    Color color;

    switch (notification['type']) {
      case 'global':
        icon = Icons.leaderboard_rounded;
        color = accentColorBlue;
        break;
      case 'friend':
        icon = Icons.person_rounded;
        color = greenStatColor;
        break;
      case 'guild':
        icon = Icons.group_rounded;
        color = accentColorPurple;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = textColor;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0), // Mantido margem vertical
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Ajustado padding para consistência
      decoration: BoxDecoration(
        color: panelBgColor.withOpacity(0.7), // Ligeiramente mais transparente
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withOpacity(0.4), width: 1.0), // Ajustado borda
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20), // Mantido tamanho do ícone
          const SizedBox(width: 8), // Mantido espaço
          Expanded(
            child: Text(
              notification['message'],
              style: TextStyle(color: textColor, fontSize: 12), // Mantido tamanho da fonte
            ),
          ),
          const SizedBox(width: 8),
          if (notification['timestamp'] != null)
            Text(
              _formatTimestamp(notification['timestamp']),
              style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 10),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    } else {
      return '${difference.inDays}d atrás';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _filterNotifications(_notifications);
    final filteredTempNotifications = _filterNotifications(_tempNotifications);

    return Container(
      margin: const EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 15.0),
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: panelBgColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: accentColorBlue.withOpacity(0.5), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: accentColorPurple.withOpacity(0.1),
            blurRadius: 10.0,
            spreadRadius: 1.0,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "NOTIFICAÇÕES RECENTES",
                style: TextStyle(
                  color: accentColorBlue,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: accentColorBlue,
                ),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                    if (_isExpanded) {
                      _animationController.forward();
                    } else {
                      _animationController.reverse();
                    }
                  });
                },
              ),
            ],
          ),
          const Divider(color: accentColorBlue, height: 20, thickness: 0.5),
          if (!_isExpanded && filteredTempNotifications.isNotEmpty)
            Column(
              children: filteredTempNotifications.map((notification) => _buildTempNotificationItem(notification)).toList(),
            ),
          if (_isExpanded)
            ...filteredNotifications.map((notification) => _buildNotificationItem(notification))
          else
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: const Text(
                "Toque para ver as notificações recentes",
                style: TextStyle(color: textColor, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Placeholder para as outras telas ---
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(title,
            style: const TextStyle(fontSize: 24, color: Colors.white)));
  }
}

// --- Widget para o Visualizador do Corpo ---
class BodyViewer extends StatefulWidget {
  const BodyViewer({super.key});

  @override
  State<BodyViewer> createState() => _BodyViewerState();
}

class _BodyViewerState extends State<BodyViewer> {
  bool _isBackView = false;

  // Helper para tradução
  String _t(String key) {
    final languageService = context.read<LanguageService>();
    return TranslationService.get(key, languageService.currentLanguageCode);
  }

  void _flipBody() {
    setState(() { _isBackView = !_isBackView; });
    print("Virando para: ${_isBackView ? 'Costas' : 'Frente'}");
  }

  List<Widget> _buildBodyOverlays() { return []; } // Placeholder for overlays

  @override
  Widget build(BuildContext context) {
    String currentImage = _isBackView ? '//costas//' : '//frente//';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset( currentImage, fit: BoxFit.contain,
                ),
                ..._buildBodyOverlays(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _flipBody,
            icon: const Icon(Icons.flip_camera_android_outlined, size: 18),
            label: Text(_isBackView ? _t('viewFront') : _t('viewBack'), style: const TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
                backgroundColor: accentColorPurple.withOpacity(0.8), foregroundColor: textColor,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            ),
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}

// --- Widget para o Painel de Missões Diárias (ATUALIZADO) ---
class DailyQuestsPanel extends StatefulWidget {
  final VoidCallback? onQuestsCompletedAndRewardsCollected;

  const DailyQuestsPanel({this.onQuestsCompletedAndRewardsCollected, super.key});

  @override
  State<DailyQuestsPanel> createState() => _DailyQuestsPanelState();
}

class _DailyQuestsPanelState extends State<DailyQuestsPanel> with WidgetsBindingObserver {
  List<Mission> _activeDailyMissions = [];
  Map<String, bool> _questStatus = {}; // mission.id -> bool
  bool _isLoadingQuests = true;
  bool _rewardsCollectedForCurrentCycle = false;
  bool _missionsLockedDueToCollection = false; // Nova flag para indicar se missões estão bloqueadas

  // Helper para tradução
  String _t(String key) {
    final languageService = context.read<LanguageService>();
    return TranslationService.get(key, languageService.currentLanguageCode);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _registerMissionUpdateCallback();
    _loadAndCheckDailyQuests();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unregisterMissionUpdateCallback();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App voltou ao foco, recarregar missões para verificar se houve mudanças
      _loadAndCheckDailyQuests();
    }
  }

  // Método público para forçar atualização das missões (chamado pela tela de missões)
  void refreshDailyMissions() {
    if (mounted) {
      _loadAndCheckDailyQuests();
    }
  }

  // Registrar callback global na inicialização
  void _registerMissionUpdateCallback() {
    _globalMissionUpdateCallback = refreshDailyMissions;
  }

  // Limpar callback na destruição
  void _unregisterMissionUpdateCallback() {
    if (_globalMissionUpdateCallback == refreshDailyMissions) {
      _globalMissionUpdateCallback = null;
    }
  }

  // Helper function to get Firestore-compatible keys
  String _getFirestoreKeyForAttribute(StatAttribute attribute) {
    switch (attribute) {
      case StatAttribute.FOR:
        return 'FOR';
      case StatAttribute.AGI:
        return 'AGI';
      case StatAttribute.VIT:
        return 'VIT';
      case StatAttribute.INT:
        return 'INT';
      case StatAttribute.PER:
        return 'PER';
      case StatAttribute.NONE:
        return '';
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
            side: BorderSide(color: isPrimary ? accentColorBlue : Colors.transparent)),
      ),
      child: Text(text.toUpperCase()),
    );
  }

  Future<T?> _showStyledDialog<T>({
    required BuildContext context, required String titleText, required List<Widget> contentWidgets,
    required List<Widget> actions, IconData icon = Icons.info_outline, Color iconColor = accentColorBlue,
  }) {
    return showDialog<T>(
      context: context, barrierDismissible: false,
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
                border: Border(bottom: BorderSide(color: accentColorPurple.withOpacity(0.5), width: 1.0))),
            child: Row( children: [
              Icon(icon, color: iconColor), const SizedBox(width: 10),
              Text(titleText.toUpperCase(), style: const TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),),
            ],),),
          content: SingleChildScrollView(child: ListBody(children: contentWidgets)),
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



  // Função auxiliar para verificar se é um novo dia
  bool _isNewDay(Timestamp? lastResetTimestamp) {
    if (lastResetTimestamp == null) return true;
    final DateTime lastResetDate = lastResetTimestamp.toDate();
    final DateTime now = DateTime.now();
    return now.year > lastResetDate.year ||
        (now.year == lastResetDate.year && now.month > lastResetDate.month) ||
        (now.year == lastResetDate.year && now.month == lastResetDate.month && now.day > lastResetDate.day);
  }

  Future<void> _loadAndCheckDailyQuests() async {
    if (!mounted) return;
    setState(() { _isLoadingQuests = true; });

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) setState(() { _isLoadingQuests = false; });
      print("Usuário não logado para carregar missões diárias.");
      return;
    }

    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      List<String> selectedIds = [];
      Map<String, bool> questStatus = {};
      bool rewardsCollected = false;
      bool needsDailyReset = false;

      if (!userSnapshot.exists) {
        // Usuário não existe, criar com dados padrão
        print("Documento do usuário não existe. Criando com padrões...");
        
        selectedIds = [
          'daily_squats_100',
          'daily_pushups_100', 
          'daily_situps_100',
          'daily_run_10km',
          'train_today'
        ];
        
        for (var id in selectedIds) {
          questStatus[id] = false;
        }

        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
          'playerName': currentUser.displayName ?? "Jogador",
          'level': 1,
          'previousLevel': 1,
          'selectedDailyQuestIds': selectedIds,
          'dailyQuestData': {
            'activeQuests': questStatus,
            'lastResetTimestamp': FieldValue.serverTimestamp(),
            'rewardsCollectedForDay': false,
            'consecutiveFailures': 0,
          },
          'email': currentUser.email ?? '',
          'exp': 0.0,
          'job': 'Nenhuma',
          'title': 'Aspirante',
          'stats': {'FOR': 10, 'VIT': 10, 'AGI': 10, 'INT': 10, 'PER': 10},
          'bonusStats': {'FOR': 0, 'VIT': 0, 'AGI': 0, 'INT': 0, 'PER': 0},
          'availableSkillPoints': 0,
          'currentHP': 100.0,
          'currentMP': 50.0,
          'fatigue': 0,
          'equippedItems': {},
          'inventory': [],
          'completedAchievements': {},
          'unlockedTitles': ['Aspirante'],
          'unlockedClasses': ['Nenhuma'],
          'titlesWithShownNotification': ['Aspirante'],
          'classesWithShownNotification': ['Nenhuma'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Usuário existe, carregar dados
        Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
        
        selectedIds = List<String>.from(userData['selectedDailyQuestIds'] ?? []);
        
        if (selectedIds.isEmpty) {
          // Se não tem missões selecionadas, usar padrão
          selectedIds = [
            'daily_squats_100',
            'daily_pushups_100', 
            'daily_situps_100',
            'daily_run_10km',
            'train_today'
          ];
          
          await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
            'selectedDailyQuestIds': selectedIds,
          });
        }

        Map<String, dynamic> dailyQuestData = Map<String, dynamic>.from(userData['dailyQuestData'] ?? {});
        Map<String, bool> storedQuests = Map<String, bool>.from(dailyQuestData['activeQuests'] ?? {});
        Timestamp? lastResetTimestamp = dailyQuestData['lastResetTimestamp'] as Timestamp?;
        
        // Verificar se é um novo dia
        if (_isNewDay(lastResetTimestamp)) {
          print("Novo dia detectado! Resetando missões diárias.");
          needsDailyReset = true;
          
          // Reset todas as missões para false
          for (var id in selectedIds) {
            questStatus[id] = false;
          }
          rewardsCollected = false;
          
          // Atualizar no Firestore
          await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
            'dailyQuestData.activeQuests': questStatus,
            'dailyQuestData.lastResetTimestamp': FieldValue.serverTimestamp(),
            'dailyQuestData.rewardsCollectedForDay': false,
          });
        } else {
          // Não é um novo dia, carregar dados existentes
          print("Mesmo dia. Carregando progresso das missões.");
          
          // Verificar se houve mudanças nas missões selecionadas
          Set<String> selectedSet = selectedIds.toSet();
          Set<String> storedSet = storedQuests.keys.toSet();
          
          if (!selectedSet.containsAll(storedSet) || !storedSet.containsAll(selectedSet)) {
            print("Missões selecionadas mudaram. Sincronizando...");
            // Sincronizar questStatus com as novas selectedIds
            Map<String, bool> newQuestStatus = {};
            for (var id in selectedIds) {
              newQuestStatus[id] = storedQuests[id] ?? false;
            }
            questStatus = newQuestStatus;
            
            // Atualizar no Firestore para manter sincronizado
            await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
              'dailyQuestData.activeQuests': questStatus,
            });
          } else {
            // Missões não mudaram, usar dados existentes
            for (var id in selectedIds) {
              questStatus[id] = storedQuests[id] ?? false;
            }
          }
          
          rewardsCollected = dailyQuestData['rewardsCollectedForDay'] ?? false;
        }
      }

      // Construir lista de missões para a UI
      List<Mission> missions = [];
      
      // Definir missões hardcoded para evitar problemas de import
      Map<String, Mission> availableMissions = {
        'daily_squats_100': Mission(
          id: 'daily_squats_100', 
          title: "100 Agachamentos", 
          description: "Fortaleça suas pernas e core.", 
          rewardAttribute: StatAttribute.FOR, 
          rewardAmount: 1, 
          isDefaultDaily: true
        ),
        'daily_pushups_100': Mission(
          id: 'daily_pushups_100', 
          title: "100 Flexões", 
          description: "Desenvolva força no peitoral, ombros e tríceps.", 
          rewardAttribute: StatAttribute.FOR, 
          rewardAmount: 1, 
          isDefaultDaily: true
        ),
        'daily_situps_100': Mission(
          id: 'daily_situps_100', 
          title: "100 Abdominais", 
          description: "Defina seu core.", 
          rewardAttribute: StatAttribute.VIT, 
          rewardAmount: 1, 
          isDefaultDaily: true
        ),
        'daily_run_10km': Mission(
          id: 'daily_run_10km', 
          title: "Correr 10km", 
          description: "Aumente sua resistência.", 
          rewardAttribute: StatAttribute.AGI, 
          rewardAmount: 1, 
          isDefaultDaily: true
        ),
        'train_today': Mission(
          id: 'train_today', 
          title: "Treinar Conforme Planejado", 
          description: "Siga seu plano de treino do dia.", 
          rewardAttribute: StatAttribute.FOR, 
          rewardAmount: 2, 
          isDefaultDaily: false
        ),
        'drink_water_2l': Mission(
          id: 'drink_water_2l', 
          title: "Beber 2L de Água", 
          description: "Hidratação é chave para a performance.", 
          rewardAttribute: StatAttribute.VIT, 
          rewardAmount: 1, 
          isDefaultDaily: false
        ),
        'read_pages_10': Mission(
          id: 'read_pages_10', 
          title: "Ler 10 Páginas de um Livro", 
          description: "Conhecimento também é poder.", 
          rewardAttribute: StatAttribute.INT, 
          rewardAmount: 1, 
          isDefaultDaily: false
        ),
        'make_bed': Mission(
          id: 'make_bed', 
          title: "Arrumar a Cama", 
          description: "Comece o dia com disciplina.", 
          rewardAttribute: StatAttribute.PER, 
          rewardAmount: 1, 
          isDefaultDaily: false
        ),
        'meditate_10min': Mission(
          id: 'meditate_10min', 
          title: "Meditar por 10 Minutos", 
          description: "Clareza mental para os desafios.", 
          rewardAttribute: StatAttribute.INT, 
          rewardAmount: 1, 
          isDefaultDaily: false
        ),
        'walk_30min': Mission(
          id: 'walk_30min', 
          title: "Caminhar por 30 Minutos", 
          description: "Mantenha o corpo ativo.", 
          rewardAttribute: StatAttribute.AGI, 
          rewardAmount: 1, 
          isDefaultDaily: false
        ),
      };

      for (var id in selectedIds) {
        if (availableMissions.containsKey(id)) {
          missions.add(availableMissions[id]!);
        }
      }

              if (mounted) {
        setState(() {
          _activeDailyMissions = missions;
          _questStatus = questStatus;
          _rewardsCollectedForCurrentCycle = rewardsCollected;
          // Se recompensas já foram coletadas, as missões ficam bloqueadas para novas alterações
          _missionsLockedDueToCollection = rewardsCollected;
        });
      }

      // Chamar callback se houve reset diário para atualizar outras partes da UI
      if (needsDailyReset) {
        widget.onQuestsCompletedAndRewardsCollected?.call();
      }

    } catch (e, s) {
      print("Erro em _loadAndCheckDailyQuests: $e\nStack: $s");
      if (mounted) { 
        setState(() {
          _activeDailyMissions = []; 
          _questStatus = {}; 
          _rewardsCollectedForCurrentCycle = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() { _isLoadingQuests = false; });
      }
    }
  }

  Widget _buildQuestItem(Mission mission) {
    bool isChecked = _questStatus[mission.id] ?? false;
    bool isLocked = _missionsLockedDueToCollection;
    
    if (mission.id == 'placeholder_id_missing') {
        return ListTile(
            title: Text(mission.title, style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            subtitle: Text(mission.description, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
        );
    }
    
    // Cores baseadas no status
    Color titleColor = isLocked ? textColor.withOpacity(0.5) : textColor;
    Color subtitleColor = isLocked ? textColor.withOpacity(0.3) : textColor.withOpacity(0.7);
    
    return Container(
      decoration: isLocked ? BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: yellowWarningColor.withOpacity(0.3), width: 1),
      ) : null,
      child: CheckboxListTile(
        title: Row(
          children: [
            if (isLocked) ...[
              Icon(Icons.lock_outlined, color: yellowWarningColor, size: 16),
              SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                mission.title, 
                style: TextStyle(
                  color: titleColor, 
                  fontSize: 15, 
                  decoration: isChecked ? TextDecoration.lineThrough : null
                )
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${_t('reward')}: +${mission.rewardAmount} ${statAttributeToString(mission.rewardAttribute)}", style: TextStyle(color: subtitleColor, fontSize: 11)),
            if (isLocked)
              Text("🔒 Desbloqueará amanhã", style: TextStyle(color: yellowWarningColor, fontSize: 10, fontStyle: FontStyle.italic)),
          ],
        ),
        value: isChecked,
        onChanged: _rewardsCollectedForCurrentCycle || _isLoadingQuests ? null : (bool? value) {
          if (value != null && mounted) {
            if (isLocked) {
              // Mostrar mensagem de bloqueio
              _showStyledDialog(
                context: context,
                titleText: "Missões Bloqueadas",
                icon: Icons.lock_outlined,
                iconColor: yellowWarningColor,
                contentWidgets: [
                  Text("As recompensas diárias já foram coletadas hoje.", style: TextStyle(color: textColor)),
                  SizedBox(height: 8),
                  Text("Novas missões só poderão ser completadas amanhã.", style: TextStyle(color: textColor.withOpacity(0.8))),
                ],
                actions: [
                  _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
                ],
              );
              return;
            }
            setState(() { _questStatus[mission.id] = value; });
            _updateQuestStatusInFirestore(mission.id, value);
          }
        },
        controlAffinity: ListTileControlAffinity.trailing,
        activeColor: isLocked ? Colors.grey : accentColorPurple, 
        checkColor: Colors.white, 
        tileColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 0),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Future<void> _updateQuestStatusInFirestore(String missionId, bool newValue) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || !mounted) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
        'dailyQuestData.activeQuests.$missionId': newValue,
      });
      print("Status da missão '$missionId' atualizado para $newValue no Firestore.");
    } catch (e) {
      print("Erro ao atualizar status da missão '$missionId' no Firestore: $e");
      if (mounted) {
        setState(() { _questStatus[missionId] = !newValue; }); 
        _showStyledDialog(
          context: context,
          titleText: "Erro",
          icon: Icons.error_outline,
          iconColor: Colors.red,
          contentWidgets: [
                            Text(_t('errorSavingMission'), style: TextStyle(color: textColor)),
          ],
          actions: [
            _buildDialogButton(context, "OK", () => Navigator.of(context).pop(), true),
          ],
        );
      }
    }
  }

  bool _areAllSelectedQuestsDone() {
    if (_activeDailyMissions.isEmpty) return false;
    return _activeDailyMissions.every((mission) => _questStatus[mission.id] ?? false);
  }

  void _collectRewards() async {
    if (!mounted) return;
    if (_isLoadingQuests) return;

    if (_rewardsCollectedForCurrentCycle) {
      _showStyledDialog(context: context, titleText: "Recompensa Já Coletada",
          icon: Icons.info_outline_rounded, iconColor: accentColorBlue,
                      contentWidgets: [Text(_t('rewardsAlreadyCollected'), textAlign: TextAlign.center, style: TextStyle(color: textColor))],
          actions: [_buildDialogButton(context, "Ok", () => Navigator.of(context).pop(), true)]
      );
      return;
    }

    if (!_areAllSelectedQuestsDone()) {
      _showStyledDialog( context: context, titleText: "Atenção!",
          icon: Icons.warning_amber_rounded, iconColor: Colors.orangeAccent,
                      contentWidgets: [ Text(_t('completeAllMissions'),
          textAlign: TextAlign.center, style: TextStyle(color: textColor, fontSize: 16),)],
          actions: [ _buildDialogButton(context, "Entendido", () => Navigator.of(context).pop(), true)]
      );
      return;
    }

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        _showStyledDialog(
            context: context, 
            titleText: "Erro de Autenticação",
            contentWidgets: [Text(_t('needLoginRewards'), style: TextStyle(color: textColor))],
            actions: [_buildDialogButton(context, "Ok", () {
                if (mounted) Navigator.of(context).pop(); 
            }, true)]
        );
      }
      return;
    }

    if (mounted) {
      setState(() { _isLoadingQuests = true; });
    }

    DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
    bool transactionSuccess = false;
    double totalExpGainedFromDailies = 0; 
    Map<StatAttribute, int> totalAttributesGained = {};
    int levelingCoinsGainedFromDailies = 0;
    int skillPointsGained = 3;

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userDocRef);
        if (!snapshot.exists) {
          throw Exception("Documento do usuário não existe!");
        }

        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        
        double currentExpDb = (data['exp'] ?? 0.0).toDouble();
                  Map<String, int> currentBaseStats = Map<String, int>.from(Map<String, dynamic>.from(data['stats'] ?? {}));
        // Assegura que todas as chaves de atributos existam em currentBaseStats, inicializadas com 0 se ausentes
        final Map<String, int> defaultZeroStats = {'FOR': 0, 'VIT': 0, 'AGI': 0, 'INT': 0, 'PER': 0};
        defaultZeroStats.forEach((key, value) {
            currentBaseStats.putIfAbsent(key, () => value);
        });

        Map<String, dynamic> dailyQuestData = Map<String, dynamic>.from(data['dailyQuestData'] ?? {});
        Map<String, bool> activeQuests = Map<String, bool>.from(dailyQuestData['activeQuests'] ?? {});
        int currentSkillPoints = data['availableSkillPoints'] ?? 0;

        // Verifica se já coletou as recompensas hoje
        if (dailyQuestData['rewardsCollectedForDay'] == true) {
          throw Exception("Recompensas já coletadas hoje!");
        }

        for (Mission mission in _activeDailyMissions) {
          if (_questStatus[mission.id] == true && mission.id != 'placeholder_id_missing') { 
            if (mission.rewardAttribute != StatAttribute.NONE) {
              String attrKey = _getFirestoreKeyForAttribute(mission.rewardAttribute); 
              if (attrKey.isNotEmpty && currentBaseStats.containsKey(attrKey)) {
                currentBaseStats[attrKey] = (currentBaseStats[attrKey] ?? 0) + mission.rewardAmount;
                totalAttributesGained[mission.rewardAttribute] = (totalAttributesGained[mission.rewardAttribute] ?? 0) + mission.rewardAmount;
              } else {
                print("Chave de atributo inválida ou não mapeada ('${attrKey}') ao coletar recompensas para missão '${mission.title}'. Atributo original: ${mission.rewardAttribute}");
              }
            }
            activeQuests[mission.id] = true; 
          }
        }
        
        if (_areAllSelectedQuestsDone() && !_rewardsCollectedForCurrentCycle) {
            levelingCoinsGainedFromDailies = 1;
            totalExpGainedFromDailies = 150; // XP das recompensas diárias
        }

        dailyQuestData['activeQuests'] = activeQuests; 
        dailyQuestData['rewardsCollectedForDay'] = true;

        Map<String, dynamic> updates = {
          'exp': currentExpDb + totalExpGainedFromDailies, 
          'stats': currentBaseStats, 
          'dailyQuestData': dailyQuestData,
          'availableSkillPoints': currentSkillPoints + skillPointsGained,
        };

        if (levelingCoinsGainedFromDailies > 0) {
          updates['levelingCoins'] = FieldValue.increment(levelingCoinsGainedFromDailies);
        }

        transaction.update(userDocRef, updates);
      });
      transactionSuccess = true;
    } catch (e, stack) { 
        print("Falha ao coletar recompensas da missão diária: $e");
        print("Stack trace: $stack");
        transactionSuccess = false;
    }

    if (!mounted) return;

    String rewardMessage = "Parabéns!\nVocê completou suas missões diárias!";
    if (totalAttributesGained.isNotEmpty) {
      rewardMessage += "\n\nRecompensas de Atributos:";
      totalAttributesGained.forEach((attr, amount) {
        rewardMessage += "\n+${amount} ${statAttributeToString(attr)}";
      });
    }
    if (totalExpGainedFromDailies > 0) {
      rewardMessage += "\n+${totalExpGainedFromDailies.toInt()} EXP";
    }
    if (levelingCoinsGainedFromDailies > 0) {
        rewardMessage += "\n+${levelingCoinsGainedFromDailies} Leveling Coin";
    }
    rewardMessage += "\n+${skillPointsGained} Pontos de Habilidade";

    if (transactionSuccess) {
      await _showStyledDialog( context: context, titleText: "Missões Diárias Completas!",
          icon: Icons.check_circle_outline_rounded, iconColor: Colors.greenAccent,
          contentWidgets: [Text(rewardMessage, textAlign: TextAlign.center, style: TextStyle(color: textColor, fontSize: 16),)],
          actions: [ _buildDialogButton(context, "Excelente!", () => Navigator.of(context).pop(), true) ]);
      if (mounted) {  
        setState(() { _rewardsCollectedForCurrentCycle = true; _isLoadingQuests = false; });
        widget.onQuestsCompletedAndRewardsCollected?.call();
        
        // Verificar level up após ganhar EXP
        if (totalExpGainedFromDailies > 0) {
          await _checkForLevelUpAfterExpGain();
        }
      }
    } else {
      await _showStyledDialog( 
          context: context, titleText: "Erro", icon: Icons.error_outline_rounded, iconColor: Colors.redAccent,
          contentWidgets: const [Text("Não foi possível registrar a recompensa. Tente novamente.", style: TextStyle(color: textColor))],
          actions: [_buildDialogButton(context, "Ok", () => Navigator.of(context).pop(), true)]
      );
      if (mounted) {
          setState(() { _isLoadingQuests = false; });
      }
    }
  }

  Future<void> _checkForLevelUpAfterExpGain() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      int currentLevel = data['level'] ?? 1;
      double currentExp = (data['exp'] ?? 0.0).toDouble();
      int currentSkillPoints = data['availableSkillPoints'] ?? 0;

      bool leveledUp = false;
      int skillPointsGained = 0;
      int expNeeded = _getExpForNextLevel(currentLevel);

      while (currentExp >= expNeeded && expNeeded > 0) {
        leveledUp = true;
        currentExp -= expNeeded;
        currentLevel++;
        int pointsPerLevel = 3;
        currentSkillPoints += pointsPerLevel;
        skillPointsGained += pointsPerLevel;
        expNeeded = _getExpForNextLevel(currentLevel);
      }

      if (leveledUp) {
        // Obter o nível anterior atual do Firestore
        final currentData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        int previousLevel = currentData.data()?['level'] ?? 1;
        
        // Salvar no Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'level': currentLevel,
          'exp': currentExp,
          'availableSkillPoints': currentSkillPoints,
          'previousLevel': previousLevel,
        });

        // Mostrar mensagem de level up
        if (mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: panelBgColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                title: Row(
                  children: const [
                    Icon(Icons.military_tech_rounded, color: levelUpColor, size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "LEVEL UP!",
                        style: TextStyle(color: levelUpColor, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Parabéns!",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Você alcançou o Nível $currentLevel!",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: textColor, fontSize: 16)
                    ),
                    if (skillPointsGained > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Você ganhou +$skillPointsGained Pontos de Habilidade!",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: greenStatColor, fontSize: 16, fontWeight: FontWeight.bold)
                        ),
                      ),
                    if (currentLevel >= 3 && (currentLevel - skillPointsGained ~/ 3) < 3)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          "🎉 Você desbloqueou as CLASSES! 🎉",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: levelUpColor, fontSize: 16, fontWeight: FontWeight.bold)
                        ),
                      ),
                    if (currentLevel % 3 == 0 && currentLevel >= 3)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Agora você pode trocar de classe!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: accentColorPurple, fontSize: 14, fontStyle: FontStyle.italic)
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: accentColorPurple,
                      foregroundColor: textColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(_t('incredible'), style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      print("Erro ao verificar level up: $e");
    }
  }

  int _getExpForNextLevel(int currentLvl) {
    if (currentLvl <= 0) return 100;
    return (100 * pow(1.35, currentLvl - 1)).round();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingQuests && _activeDailyMissions.isEmpty) { 
      return Container(
        height: 250, 
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: accentColorPurple),
      );
    }
    
    if (!_isLoadingQuests && _activeDailyMissions.isEmpty){
        return Container(
            margin: const EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 15.0),
            padding: const EdgeInsets.all(15.0),
            height: 200, 
            decoration: BoxDecoration(
                color: panelBgColor, borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: accentColorBlue.withOpacity(0.5), width: 1.0),
            ),
            child: Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list_alt_outlined, color: textColor.withOpacity(0.7), size: 40),
                SizedBox(height: 10),
                Text(_t('noMissionsSelected'), textAlign: TextAlign.center, style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 16)),
                SizedBox(height: 5),
                                  Text(_t('goToMissionsScreen'), textAlign: TextAlign.center, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13)),
              ],
            )),
        );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 15.0),
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration( color: panelBgColor, borderRadius: BorderRadius.circular(12.0), border: Border.all(color: accentColorBlue.withOpacity(0.5), width: 1.0),
        boxShadow: [ BoxShadow( color: accentColorPurple.withOpacity(0.1), blurRadius: 10.0, spreadRadius: 1.0,) ]),
      child: Column( mainAxisSize: MainAxisSize.min, children: [
                  Text(_t('dailyMissions').toUpperCase(), style: TextStyle(color: accentColorBlue, fontSize: 18.0, fontWeight: FontWeight.bold, letterSpacing: 1.5,)),
        const Divider(color: accentColorBlue, height: 20, thickness: 0.5),
        if (_isLoadingQuests) 
             Padding(
               padding: const EdgeInsets.symmetric(vertical: 20.0),
               child: CircularProgressIndicator(color: accentColorPurple.withOpacity(0.7)),
             )
        else
            ..._activeDailyMissions.map((mission) => _buildQuestItem(mission)),
        
        if (!_isLoadingQuests && _activeDailyMissions.isNotEmpty) ...[
            const Divider(color: accentColorBlue, height: 20, thickness: 0.5),
            ElevatedButton(
            onPressed: _rewardsCollectedForCurrentCycle || _isLoadingQuests || _activeDailyMissions.isEmpty ? null : _collectRewards,
            style: ElevatedButton.styleFrom(
                backgroundColor: _areAllSelectedQuestsDone() && !_rewardsCollectedForCurrentCycle ? Colors.green.shade600 : accentColorPurple.withOpacity(0.8),
                disabledBackgroundColor: Colors.grey.shade700,
                foregroundColor: textColor, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
            child: Text(_rewardsCollectedForCurrentCycle ? _t('rewardCollected') : _t('collectRewards'))),
            const SizedBox(height: 15),
                          Row( 
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18), 
                  const SizedBox(width: 8),
                  Expanded( 
                    child: Text(
                      _t('attentionPenalty'),
                      textAlign: TextAlign.center, 
                      style: const TextStyle(
                        color: Colors.redAccent, 
                        fontSize: 12, 
                        fontStyle: FontStyle.italic
                      ),
                    ),
                  ),
                ],
              ),
        ] else if (!_isLoadingQuests && _activeDailyMissions.isEmpty)
            Container(), 
        
      ],),);
  }
}


// --- EquipmentSlotWidget ---
class EquipmentSlotWidget extends StatelessWidget {
  final String slotName;
  final IconData placeholderIcon;
  final bool isEquipped;
  final VoidCallback? onTap;
  final Map<String, dynamic>? equippedItem;

  const EquipmentSlotWidget({
    required this.slotName,
    required this.placeholderIcon,
    this.isEquipped = false,
    this.onTap,
    this.equippedItem,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    switch (rank) {
      case 'SSS':
        return Colors.purpleAccent;
      case 'SS':
        return Colors.deepPurpleAccent;
      case 'S':
        return Colors.amberAccent;
      case 'A':
        return Colors.redAccent;
      case 'B':
        return Colors.orangeAccent;
      case 'C':
        return Colors.yellowAccent;
      case 'D':
        return Colors.greenAccent;
      case 'E':
        return Colors.blueAccent;
      default:
        return accentColorBlue;
    }
  }
}

// --- Widget para Painel de Status (Somente Visualização) ATUALIZADO ---
class ViewOnlyStatsPanel extends StatelessWidget {
  final String playerName;
  final int level;
  final String currentJob;
  final String currentTitle;
  final double hp;
  final double maxHp;
  final double mp;
  final double maxMp;
  final Map<String, int> baseStats;
  final Map<String, int> bonusStats;
  final Map<String, int> itemBonusStats;
  final int availableSkillPoints;
  final double currentExp;
  final int expToNextLevel;
  final int levelingCoins;
  final Map<String, bool> completedAchievements;

  const ViewOnlyStatsPanel({
    required this.playerName,
    required this.level,
    required this.currentJob,
    required this.currentTitle,
    required this.hp,
    required this.maxHp,
    required this.mp,
    required this.maxMp,
    required this.baseStats,
    required this.bonusStats,
    required this.itemBonusStats,
    required this.availableSkillPoints,
    required this.currentExp,
    required this.expToNextLevel,
    required this.levelingCoins,
    required this.completedAchievements,
    super.key,
  });




  Widget _buildStatRowDisplay(IconData icon, String labelKey, int baseValue, int bonusValue) {
    int totalValue = baseValue + bonusValue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
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
        ],
      ),
    );
  }

  Widget _buildProgressBarDisplay(String label, double value, double maxValue, Color barColor) {
    final double percentage = (maxValue > 0 && value >= 0) ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Stack(children: [
            Container(height: 8, decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(4),),),
            FractionallySizedBox(widthFactor: percentage, child: Container(height: 8, decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(4),
              boxShadow: [ BoxShadow( color: barColor.withOpacity(0.5), blurRadius: 3.0, spreadRadius: 0.5,)]),),),
          ],),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usar função centralizada para calcular aura
    int calculatedAura = aura_utils.calculateTotalAura(
      baseStats: baseStats,
      bonusStats: bonusStats,
      currentTitle: currentTitle,
      currentJob: currentJob,
      level: level,
      completedAchievements: completedAchievements,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: panelBgColor, borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: accentColorBlue.withOpacity(0.5), width: 1.0),
        boxShadow: [ BoxShadow(color: accentColorPurple.withOpacity(0.2), blurRadius: 8.0, spreadRadius: 1.0,)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text("$level", style: TextStyle( color: accentColorBlue, fontSize: 44, fontWeight: FontWeight.bold, shadows: [Shadow(color: accentColorBlue.withOpacity(0.5), blurRadius: 7.0)],)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(playerName.toUpperCase(), style: TextStyle(color: accentColorBlue, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  Text("CLASSE: $currentJob", style: const TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500)),
                  Text("TÍTULO: $currentTitle", style: const TextStyle(color: textColor, fontSize: 10, fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis,),],))
          ]),
          const SizedBox(height: 5),
          _buildProgressBarDisplay("XP", currentExp, expToNextLevel.toDouble(), Colors.lightGreenAccent.shade700),
          Padding(padding: const EdgeInsets.only(left: 2.0, bottom: 4.0, top:1), child: Text("${currentExp.toInt()}/${expToNextLevel.toInt()} EXP", style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 10))),
          Divider(color: accentColorBlue.withOpacity(0.3), height: 10, thickness: 0.3),
          _buildProgressBarDisplay("HP", hp, maxHp, Colors.redAccent),
          Padding(padding: const EdgeInsets.only(left: 2.0, bottom: 4.0, top:1), child: Text("${hp.toInt()}/${maxHp.toInt()} HP", style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 10))),
          _buildProgressBarDisplay("MP", mp, maxMp, Colors.blueAccent),
          Padding(padding: const EdgeInsets.only(left: 2.0, bottom: 4.0, top:1), child: Text("${mp.toInt()}/${maxMp.toInt()} MP", style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 10))),
          Divider(color: accentColorBlue.withOpacity(0.3), height: 10, thickness: 0.3),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                mainAxisSize: MainAxisSize.min, 
                children: [
                  _buildStatRowDisplay(Icons.fitness_center, "FOR", baseStats['FOR'] ?? 0, bonusStats['FOR'] ?? 0),
                  _buildStatRowDisplay(Icons.directions_run, "AGI", baseStats['AGI'] ?? 0, bonusStats['AGI'] ?? 0),
                  _buildStatRowDisplay(Icons.visibility, "PER", baseStats['PER'] ?? 0, bonusStats['PER'] ?? 0),
                ],
              ),
              
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.whatshot_rounded, color: prColor, size: 24),
                  const SizedBox(height: 4),
                  Text("AURA TOTAL", style: TextStyle(color: accentColorBlue, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  Text("$calculatedAura", style: TextStyle(color: prColor, fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.monetization_on, color: Colors.yellowAccent, size: 20),
                      const SizedBox(width: 5),
                      Text(
                        "$levelingCoins",
                        style: const TextStyle(
                          color: Colors.yellowAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                mainAxisSize: MainAxisSize.min, 
                children: [
                  _buildStatRowDisplay(Icons.favorite, "VIT", baseStats['VIT'] ?? 0, bonusStats['VIT'] ?? 0),
                  _buildStatRowDisplay(Icons.psychology, "INT", baseStats['INT'] ?? 0, bonusStats['INT'] ?? 0),
                  Padding( 
                    padding: const EdgeInsets.symmetric(vertical: 3.5),
                    child: Row( 
                      children: [
                        const Icon(Icons.star_outline_rounded, color: greenStatColor, size: 18),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 40,
                          child: const Text(
                            "PTS:",
                            style: TextStyle(color: greenStatColor, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          "$availableSkillPoints",
                          style: const TextStyle(color: greenStatColor, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Tela Principal (HomeScreen) ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoadingUserData = true;
  String _playerName = "Jogador";
  int _level = 1;
  String _currentJob = "Nenhuma";
  String _currentTitle = "Aspirante";
  double _hp = 100;
  double _maxHp = 100;
  double _mp = 50;
  double _maxMp = 50;
  Map<String, int> _baseStats = { 'FOR': 10, 'VIT': 10, 'AGI': 10, 'INT': 10, 'PER': 10, };
  Map<String, int> _bonusStats = { 'FOR': 0, 'VIT': 0, 'AGI': 0, 'INT': 0, 'PER': 0, };
  Map<String, bool> _completedAchievements = {};

  int _availableSkillPoints = 0;
  double _currentExp = 0;
  int _expToNextLevel = 100;
  List<Map<String, dynamic>> _inventory = [];
  Map<String, dynamic> _equippedItems = {};
  int _levelingCoins = 0;

  // Adicionar lista de itens equipados
  List<Item> _equippedItemsList = [];

  @override
  void initState() {
    super.initState();
    _loadInitialUserData();
    _loadInventoryItems();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        if (user == null) {
          print('Usuário deslogou, resetando dados da HomeScreen.');
          setState(() {
            _isLoadingUserData = false; 
            _playerName = "Jogador"; _level = 1; _currentJob = "Nenhuma"; _currentTitle = "Aspirante";
            _hp = 100; _maxHp = 100; _mp = 50; _maxMp = 50;
            _baseStats = { 'FOR': 10, 'VIT': 10, 'AGI': 10, 'INT': 10, 'PER': 10, };
            _bonusStats = { 'FOR': 0, 'VIT': 0, 'AGI': 0, 'INT': 0, 'PER': 0, };

            _availableSkillPoints = 0; _currentExp = 0; _expToNextLevel = 100;
            _inventory = [];
            _equippedItems = {};
            _levelingCoins = 0;
            _equippedItemsList = [];
          });
        } else {
          if (mounted) {
            _loadInitialUserData();
            _loadInventoryItems();
          }
        }
      }
    });
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
        _inventory = inventorySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Item Desconhecido',
            'slotType': data['type'] ?? 'Desconhecido',
            'rank': data['rank'] ?? 'E',
            'dateAcquired': (data['acquiredAt'] as Timestamp).toDate(),
            'icon': _getIconForSlotType(data['type'] ?? 'Desconhecido'),
            'isNew': data['isNew'] ?? true,
            'statBonuses': Map<String, dynamic>.from(data['statBonuses'] ?? {}),
          };
        }).toList();

        // Atualizar lista de itens equipados
        _updateEquippedItemsList();
      });
      

    } catch (e) {
      print('Erro ao carregar inventário: $e');
    }
  }

  void _updateEquippedItemsList() {
    _equippedItemsList = [];
    _equippedItems.forEach((slotType, itemId) {
      if (itemId != null) {
        final item = _inventory.firstWhere(
          (item) => item['id'] == itemId,
          orElse: () => <String, dynamic>{},
        );
        if (item.isNotEmpty) {
          _equippedItemsList.add(Item(
            id: item['id'],
            name: item['name'],
            slotType: item['slotType'],
            rank: item['rank'],
            dateAcquired: item['dateAcquired'],
            icon: item['icon'],
            isNew: item['isNew'],
            statBonuses: Map<String, int>.from(item['statBonuses']),
          ));
        }
      }
    });
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

  Widget _buildEquipmentColumn({required bool isLeft}) {
    final List<Map<String, dynamic>> slots = isLeft
        ? [ {'name': 'Cabeça', 'icon': Icons.account_circle_outlined, 'type': 'Cabeça'},
            {'name': 'Peitoral', 'icon': Icons.shield_outlined, 'type': 'Peitoral'},
            {'name': 'Mão Direita', 'icon': Icons.pan_tool_alt_outlined, 'type': 'Mão Direita'}, 
            {'name': 'Pernas', 'icon': Icons.accessibility_new_outlined, 'type': 'Pernas'},
            {'name': 'Pés', 'icon': Icons.do_not_step, 'type': 'Pés'}, 
            {'name': 'Acessório E.', 'icon': Icons.star_border_outlined, 'type': 'Acessório E.'},] 
        : [ {'name': 'Orelhas', 'icon': Icons.earbuds_outlined, 'type': 'Orelhas'}, 
            {'name': 'Colar', 'icon': Icons.circle_outlined, 'type': 'Colar'}, 
            {'name': 'Mão Esquerda', 'icon': Icons.pan_tool_alt_outlined, 'type': 'Mão Esquerda'}, 
            {'name': 'Rosto', 'icon': Icons.face_retouching_natural_outlined, 'type': 'Rosto'}, 
            {'name': 'Bracelete', 'icon': Icons.watch_later_outlined, 'type': 'Bracelete'}, 
            {'name': 'Acessório D.', 'icon': Icons.star_border_outlined, 'type': 'Acessório D.'},]; 

    return SizedBox( width: 100, 
      child: Column( mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: slots.map((slot) {
          final String slotType = slot['type'] as String;
          final String? equippedItemId = _equippedItems[slotType];
          final bool isEquipped = equippedItemId != null;

          Map<String, dynamic>? equippedItem;
          if (equippedItemId != null) {
            equippedItem = _inventory.firstWhere(
              (item) => item['id'] == equippedItemId,
              orElse: () => <String, dynamic>{},
            );
          }

          return EquipmentSlotWidget(
            slotName: slot['name'],
            placeholderIcon: slot['icon'],
            isEquipped: isEquipped,
            equippedItem: equippedItem?.isNotEmpty == true ? equippedItem : null,
            onTap: () => _goToProfile(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: 
        if (_isLoadingUserData) {
          return const Center(child: CircularProgressIndicator(color: accentColorPurple));
        }

        // Os bônus são passados separadamente para exibição correta

        return SingleChildScrollView(
          child: Column( children: [
              Padding( padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
                child: Row( crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    _buildEquipmentColumn(isLeft: true),
                    const Spacer(),
                    _buildEquipmentColumn(isLeft: false),
                  ],),),
              ViewOnlyStatsPanel( 
                playerName: _playerName, level: _level, currentJob: _currentJob, currentTitle: _currentTitle,
                hp: _hp, maxHp: _maxHp, mp: _mp, maxMp: _maxMp,
                baseStats: _baseStats, bonusStats: _bonusStats,
                itemBonusStats: _bonusStats,
                availableSkillPoints: _availableSkillPoints,
                currentExp: _currentExp, expToNextLevel: _expToNextLevel,
                levelingCoins: _levelingCoins,
                completedAchievements: _completedAchievements,
              ),
              RecentNotificationsPanel(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
              DailyQuestsPanel(onQuestsCompletedAndRewardsCollected: _loadInitialUserData), 
              const SizedBox(height: 20), 
            ],),);
      case 1: return const TreinoScreen();
      case 2: return const TelaMissoesScreen(); 
      case 3: return const ConquistasScreen();
      case 4: return const SocialScreen(); 
      default: return const Center(child: Text("Erro de Navegação"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      drawer: const SettingsScreen(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.settings, color: accentColorBlue, size: 28),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  tooltip: 'Configurações',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.donut_large, color: accentColorBlue, size: 28),
                onPressed: _goToItemRouletteScreen,
                tooltip: 'Roleta de Itens',
              ),
            ],
          ),
        ),
        title: const Text(
          'GYM LEVELING',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(blurRadius: 8.0, color: accentColorBlue, offset: Offset(0, 0)),
            ],
          ),

        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded, color: accentColorBlue, size: 28),
            onPressed: _goToRankingScreen,
            tooltip: 'Ranking Global',
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: accentColorBlue, size: 30),
            onPressed: _goToProfile,
            tooltip: 'Perfil do Jogador',
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center_rounded), label: 'Treino'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in_outlined), label: 'Missões'), 
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), label: 'Conquistas'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Social'),
        ],
        currentIndex: _selectedIndex, selectedItemColor: accentColorPurple,
        unselectedItemColor: Colors.grey.shade600, onTap: _onItemTapped,
        backgroundColor: bottomNavBgColor, type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true, 
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), 
        unselectedLabelStyle: const TextStyle(fontSize: 11), 
      ),
    );
  }

  Future<void> _loadInitialUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _playerName = data['playerName'] ?? "Jogador";
          _level = data['level'] ?? 1;
          _currentJob = data['job'] ?? "Nenhuma";
          _currentTitle = data['title'] ?? "Aspirante";
          _maxHp = 100.0 + ((data['level'] ?? 1) - 1) * 10.0;
          _hp = _maxHp; // Sempre HP completo
          _maxMp = 50.0 + ((data['level'] ?? 1) - 1) * 5.0;
          _mp = _maxMp; // Sempre MP completo
                  _baseStats = Map<String, int>.from(Map<String, dynamic>.from(data['stats'] ?? {}));
        _bonusStats = Map<String, int>.from(Map<String, dynamic>.from(data['bonusStats'] ?? {}));
        _completedAchievements = Map<String, bool>.from(data['completedAchievements'] ?? {});
        _availableSkillPoints = data['availableSkillPoints'] ?? 0;
          _currentExp = (data['exp'] ?? 0.0).toDouble();
          _expToNextLevel = 100 * _level;
          _levelingCoins = data['levelingCoins'] ?? 0;
          _equippedItems = Map<String, dynamic>.from(data['equippedItems'] ?? {});
          

        });
        
        // Carregar inventário
        await _loadInventoryItems();
      }
    } catch (e) {
      print('Erro ao carregar dados do usuário: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
      }
    }
  }



  void _onItemTapped(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _goToProfile() async {
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
      // Recarregar dados quando voltar da tela de perfil
      if (mounted) {
        _loadInitialUserData();
        _loadInventoryItems();
      }
    }
  }

  void _goToRankingScreen() {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RankingScreen()),
      );
    }
  }

  void _goToItemRouletteScreen() {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ItemRouletteScreen()),
      );
    }
  }
}
