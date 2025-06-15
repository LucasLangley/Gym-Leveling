// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import '../services/language_service.dart';
import '../services/translation_service.dart';

// Cores globais (importadas da home_screen.dart)
const Color primaryColor = Color(0xFF0A0E21);
const Color accentColorBlue = Color(0xFF40C4FF);
const Color accentColorPurple = Color(0xFF8A2BE2);
const Color textColor = Colors.white;
const Color panelBgColor = Color(0x991D1E33);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showGlobalNotifications = true;
  bool _showGuildNotifications = true;
  bool _showFriendNotifications = true;
  int _restTime = 60; // Tempo de descanso padrão em segundos

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showGlobalNotifications = prefs.getBool('showGlobalNotifications') ?? true;
      _showGuildNotifications = prefs.getBool('showGuildNotifications') ?? true;
      _showFriendNotifications = prefs.getBool('showFriendNotifications') ?? true;
      _restTime = prefs.getInt('restTime') ?? 60;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showGlobalNotifications', _showGlobalNotifications);
    await prefs.setBool('showGuildNotifications', _showGuildNotifications);
    await prefs.setBool('showFriendNotifications', _showFriendNotifications);
    await prefs.setInt('restTime', _restTime);
  }

  String _t(String key) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
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

  Future<void> _showLogoutConfirmation() async {
    await _showStyledDialog(
      context: context,
      titleText: _t('logoutConfirmation'),
      icon: Icons.logout,
      iconColor: Colors.redAccent,
      contentWidgets: [
        Text(
          _t('logoutConfirmationMessage'),
          style: const TextStyle(color: textColor),
          textAlign: TextAlign.center,
        ),
      ],
      actions: [
        _buildDialogButton(context, _t('logoutButton'), () async {
          Navigator.of(context).pop();
          await _performLogout();
        }, true),
        _buildDialogButton(context, _t('cancel'), () => Navigator.of(context).pop(), false),
      ],
    );
  }

  Future<void> _performLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showStyledDialog(
          context: context,
          titleText: _t('error'),
          icon: Icons.error_outline,
          iconColor: Colors.red,
          contentWidgets: [
            Text("${_t('logoutError')}: $e", style: const TextStyle(color: textColor)),
          ],
          actions: [
            _buildDialogButton(context, _t('ok'), () => Navigator.of(context).pop(), true),
          ],
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Drawer(
          backgroundColor: primaryColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: accentColorPurple.withOpacity(0.3),
                  border: Border(
                    bottom: BorderSide(
                      color: accentColorBlue.withOpacity(0.5),
                      width: 1.0,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.settings,
                      color: accentColorBlue,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _t('settings'),
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('notifications'),
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: Text(
                        _t('globalNotifications'),
                        style: const TextStyle(color: textColor),
                      ),
                      value: _showGlobalNotifications,
                      activeColor: accentColorPurple,
                      checkColor: textColor,
                      onChanged: (bool? value) {
                        setState(() {
                          _showGlobalNotifications = value ?? true;
                          _saveSettings();
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: Text(
                        _t('guildNotifications'),
                        style: const TextStyle(color: textColor),
                      ),
                      value: _showGuildNotifications,
                      activeColor: accentColorPurple,
                      checkColor: textColor,
                      onChanged: (bool? value) {
                        setState(() {
                          _showGuildNotifications = value ?? true;
                          _saveSettings();
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: Text(
                        _t('friendNotifications'),
                        style: const TextStyle(color: textColor),
                      ),
                      value: _showFriendNotifications,
                      activeColor: accentColorPurple,
                      checkColor: textColor,
                      onChanged: (bool? value) {
                        setState(() {
                          _showFriendNotifications = value ?? true;
                          _saveSettings();
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _t('restTimeDefault'),
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: accentColorBlue),
                          onPressed: () {
                            if (_restTime > 30) {
                              setState(() {
                                _restTime -= 30;
                                _saveSettings();
                              });
                            }
                          },
                        ),
                        Expanded(
                          child: Text(
                            '$_restTime',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: accentColorBlue),
                          onPressed: () {
                            setState(() {
                              _restTime += 30;
                              _saveSettings();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _t('language'),
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: panelBgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: accentColorBlue.withOpacity(0.5),
                        ),
                      ),
                      child: DropdownButton<String>(
                        value: languageService.currentLanguageName,
                        isExpanded: true,
                        dropdownColor: primaryColor,
                        style: const TextStyle(color: textColor),
                        underline: const SizedBox(),
                        items: [
                          DropdownMenuItem(
                            value: 'Português',
                            child: Text(_t('portuguese')),
                          ),
                          DropdownMenuItem(
                            value: 'English',
                            child: Text(_t('english')),
                          ),
                        ],
                        onChanged: (String? value) async {
                          if (value != null) {
                            String languageCode = value == 'English' ? 'en' : 'pt';
                            await languageService.changeLanguage(languageCode);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Seção de Logout
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.redAccent.withOpacity(0.8),
                            Colors.red.withOpacity(0.6),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.5),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: _showLogoutConfirmation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.logout,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _t('logout'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 