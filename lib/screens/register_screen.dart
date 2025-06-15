// Em lib/screens/register_screen.dart
// ignore_for_file: avoid_print, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import '../services/language_service.dart';
import '../services/translation_service.dart';

// Cores
const Color primaryColor = Color(0xFF0A0E21);
const Color accentColorBlue = Color(0xFF00BFFF);
const Color accentColorPurple = Color(0xFF8A2BE2);
const Color inputBackgroundColor = Color(0xFF1D1E33);
const Color textColor = Colors.white;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  String _t(String key) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    return TranslationService.get(key, languageService.currentLanguageCode);
  }

  Widget _buildDialogButton(String text, VoidCallback onPressed, bool isPrimary) {
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
    required BuildContext context, required String titleText,
    required List<Widget> contentWidgets, required List<Widget> actions,
    IconData icon = Icons.info_outline_rounded, Color iconColor = accentColorBlue,
  }) {
    return showDialog<T>(
      context: context, barrierDismissible: false,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          backgroundColor: primaryColor.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
            side: BorderSide(color: accentColorBlue.withOpacity(0.7), width: 1.5,),),
          title: Container( padding: const EdgeInsets.only(bottom: 10.0),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: accentColorPurple.withOpacity(0.5), width: 1.0))),
            child: Row(children: [
                Icon(icon, color: iconColor), const SizedBox(width: 10),
                Text(titleText.toUpperCase(),
                  style: const TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18,),),
              ],),),
          content: SingleChildScrollView(child: ListBody(children: contentWidgets,),),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actionsPadding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
          actions: actions,);},);
  }

  Future<void> _createInitialUserDataInFirestore(User user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'playerName': user.displayName ?? _t('player'),
        'email': user.email,
        'level': 1,
        'previousLevel': 1,
        'job': _t('none'),
        'title': _t('aspirant'),
        'stats': { 'FOR': 10, 'VIT': 10, 'AGI': 10, 'INT': 10, 'PER': 10,},
        'bonusStats': { 'FOR': 0, 'VIT': 0, 'AGI': 0, 'INT': 0, 'PER': 0,},
        'availableSkillPoints': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'exp': 0,
        'completedAchievements': {},
        'unlockedTitles': [_t('aspirant')],
        'unlockedClasses': [_t('none')],
        'titlesWithShownNotification': [_t('aspirant')],
        'classesWithShownNotification': [_t('none')],
        'hasCompletedIntro': false,
      });
      print("Dados iniciais do usuário criados no Firestore para ${user.uid}");
    } catch (e) {
      print("Erro ao criar dados do usuário no Firestore: $e");
      if (mounted) {
        _showStyledDialog(
            context: context,
            titleText: _t('criticalError'),
            icon: Icons.error_rounded,
            iconColor: Colors.red,
            contentWidgets: [Text(_t('profileSetupError'), style: const TextStyle(color: textColor))],
            actions: [_buildDialogButton(_t('ok'), () => Navigator.of(context).pop(), true)]
        );
      }
    }
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showStyledDialog(
            context: context, titleText: _t('registrationError'), icon: Icons.error_outline_rounded, iconColor: Colors.redAccent,
            contentWidgets: [Text(_t('passwordMismatch'), style: const TextStyle(color: textColor))],
            actions: [_buildDialogButton(_t('ok'), () => Navigator.of(context).pop(), true)]);
        return;
      }
      setState(() { _isLoading = true; });
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        User? user = userCredential.user;
        if (user != null) {
          await _createInitialUserDataInFirestore(user);

          if (!mounted) return;
          _showStyledDialog(
              context: context,
              titleText: _t('doubleDungeon'),
              icon: Icons.celebration_rounded,
              iconColor: Colors.amberAccent,
              contentWidgets: [Text(_t('doubleDungeonMessage'), textAlign: TextAlign.center, style: const TextStyle(color: textColor))],
              actions: [
                _buildDialogButton(_t('toLogin'), () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                }, true)
              ]);
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = _t('registrationError');
        if (e.code == 'weak-password') { errorMessage = _t('weakPassword');
        } else if (e.code == 'email-already-in-use') { errorMessage = _t('emailInUse');
        } else if (e.code == 'invalid-email') { errorMessage = _t('invalidEmailFormat');}
        print("Erro de registro: $e");
        _showStyledDialog( context: context, titleText: _t('registrationFailed'), icon: Icons.error_outline_rounded, iconColor: Colors.redAccent,
            contentWidgets: [Text(errorMessage, style: const TextStyle(color: textColor))],
            actions: [_buildDialogButton(_t('ok'), () => Navigator.of(context).pop(), true)]);
      } finally {
        if (mounted) { setState(() { _isLoading = false; });}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final InputDecoration inputDecoration = InputDecoration(
          filled: true, fillColor: inputBackgroundColor.withOpacity(0.6),
          labelStyle: const TextStyle(color: textColor), 
          hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
          enabledBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: accentColorBlue.withOpacity(0.5), width: 1.0),),
          focusedBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: accentColorPurple, width: 2.0),),
          errorBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),),
          focusedErrorBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),),
        );

        return Scaffold(
          backgroundColor: primaryColor,
          appBar: AppBar(
            title: Text(_t('becomePlayerTitle'), style: const TextStyle(color: textColor)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: accentColorBlue),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [primaryColor, Color(0xFF050711)],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        _t('foundDoubleDungeon'),
                        textAlign: TextAlign.center,
                        style: const TextStyle( color: accentColorBlue, fontSize: 28.0, fontWeight: FontWeight.bold,
                          shadows: [ Shadow(blurRadius: 10.0, color: accentColorPurple, offset: Offset(0, 0),),],),
                      ),
                      const SizedBox(height: 40.0),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: textColor),
                        decoration: inputDecoration.copyWith(labelText: _t('email'), prefixIcon: const Icon(Icons.email_outlined, color: accentColorBlue),),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return _t('pleaseEnterEmail');
                          if (!value.contains('@') || !value.contains('.')) return _t('enterValidEmail');
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(color: textColor),
                        obscureText: !_isPasswordVisible,
                        decoration: inputDecoration.copyWith(labelText: _t('dungeonKey'),
                          prefixIcon: const Icon(Icons.vpn_key_outlined, color: accentColorBlue),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: accentColorPurple,),
                            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),),),
                        validator: (value) => value == null || value.length < 6 ? _t('passwordMinLength') : null,
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        controller: _confirmPasswordController,
                        style: const TextStyle(color: textColor),
                        obscureText: !_isConfirmPasswordVisible,
                        decoration: inputDecoration.copyWith(labelText: _t('confirmDungeonKey'),
                          prefixIcon: const Icon(Icons.vpn_key_rounded, color: accentColorBlue),
                          suffixIcon: IconButton(
                            icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: accentColorPurple,),
                            onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),),),
                        validator: (value) {
                          if (value == null || value.isEmpty) return _t('pleaseConfirmPassword');
                          if (value != _passwordController.text) return _t('passwordMismatch');
                          return null;
                        },
                      ),
                      const SizedBox(height: 40.0),
                      _isLoading
                        ? const Center(child: CircularProgressIndicator(color: accentColorPurple))
                        : Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30.0),
                              gradient: const LinearGradient(colors: [accentColorBlue, accentColorPurple], begin: Alignment.centerLeft, end: Alignment.centerRight,),
                               boxShadow: [ BoxShadow(color: accentColorPurple.withOpacity(0.5), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, 3),),],),
                            child: ElevatedButton(
                              onPressed: _registerUser,
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15.0), backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0),),),
                              child: Text(_t('forceOpen'), style: const TextStyle(color: textColor, fontSize: 18.0, fontWeight: FontWeight.bold,),),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

   @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}