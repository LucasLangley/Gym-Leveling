// Em lib/screens/login_screen.dart
// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart'; 
import 'register_screen.dart'; // Mantido, pois _signUp navega para cá
import 'initial_profile_setup_screen.dart';
import '../services/language_service.dart';
import '../services/translation_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailResetController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  final _storage = const FlutterSecureStorage();
  static const String _keyEmail = 'saved_email';
  static const String _keyPassword = 'saved_password';
  static const String _keyRememberMe = 'remember_me_preference';

  // --- CORES ---
  static const Color primaryColor = Color(0xFF0A0E21);
  static const Color accentColorBlue = Color(0xFF00BFFF);
  static const Color accentColorPurple = Color(0xFF8A2BE2);
  static const Color inputBackgroundColor = Color(0xFF1D1E33); // Usado em inputDecoration
  static const Color textColor = Colors.white;
  // --- FIM CORES ---

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  String _t(String key) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    return TranslationService.get(key, languageService.currentLanguageCode);
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final String? savedRememberMe = await _storage.read(key: _keyRememberMe);
      if (savedRememberMe == 'true') {
        final String? email = await _storage.read(key: _keyEmail);
        final String? password = await _storage.read(key: _keyPassword);
        if (email != null && password != null) {
          if (mounted) {
            setState(() {
              _usernameController.text = email;
              _passwordController.text = password;
              _rememberMe = true;
            });
          }
        }
      }
    } catch (e) {
      print("Erro ao carregar credenciais salvas: $e");
    }
  }

  Future<void> _handleCredentialsStorage() async {
    try {
      if (_rememberMe) {
        await _storage.write(key: _keyEmail, value: _usernameController.text.trim());
        await _storage.write(key: _keyPassword, value: _passwordController.text);
        await _storage.write(key: _keyRememberMe, value: 'true');
        print("Credenciais salvas.");
      } else {
        await _storage.delete(key: _keyEmail);
        await _storage.delete(key: _keyPassword);
        await _storage.write(key: _keyRememberMe, value: 'false');
        print("Credenciais removidas.");
      }
    } catch (e) {
      print("Erro ao manusear storage de credenciais: $e");
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
    required BuildContext context, required String titleText,
    required List<Widget> contentWidgets, required List<Widget> actions,
    IconData icon = Icons.info_outline_rounded, Color iconColor = accentColorBlue, 
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          backgroundColor: primaryColor.withOpacity(0.95), 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
            side: BorderSide(color: accentColorBlue.withOpacity(0.7), width: 1.5,),
          ),
          title: Container(
            padding: const EdgeInsets.only(bottom: 10.0),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: accentColorPurple.withOpacity(0.5), width: 1.0))),
            child: Row(children: [
                Icon(icon, color: iconColor), const SizedBox(width: 10),
                Text(titleText.toUpperCase(),
                  style: const TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18,),
                ),
              ],),
          ),
          content: SingleChildScrollView(child: ListBody(children: contentWidgets,),),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actionsPadding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
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

  Future<void> _login() async {
    if (!mounted) return;
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showStyledDialog(
          context: context, titleText: _t('missingItems'),
          icon: Icons.error_outline_rounded, iconColor: Colors.redAccent,
          contentWidgets: [Text(_t('fillEmailPassword'), style: const TextStyle(color: textColor),)],
          actions: [_buildDialogButton(context, _t('ok'), () => Navigator.of(context).pop(), true)]);
      return;
    }
    setState(() { _isLoading = true; });
    await _handleCredentialsStorage();
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      print("Login bem-sucedido: ${userCredential.user?.uid}");
      if (!mounted || userCredential.user == null) {
         if (mounted) setState(() { _isLoading = false; });
         return;
      }
      User currentUser = userCredential.user!;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      bool hasCompletedIntro = false;
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data() as Map<String, dynamic>;
        hasCompletedIntro = data['hasCompletedIntro'] ?? false;
      } else {
        print("Aviso: Documento do usuário não encontrado no Firestore durante o login. Assumindo que a introdução não foi completada.");
      }

      if (!hasCompletedIntro) {
        final bool? aceitouQuest = await _showStyledDialog<bool>(
            context: context, titleText: _t('newMission'), icon: Icons.warning_amber_rounded, iconColor: Colors.orangeAccent,
            contentWidgets: [
              Text(_t('secretMission'), style: const TextStyle(color: textColor, fontSize: 16),),
              const SizedBox(height: 15),
              Text(_t('heartWarning'), style: const TextStyle(color: Colors.orangeAccent, fontSize: 14),),
              const SizedBox(height: 10),
              Text(_t('acceptMission'), style: const TextStyle(color: textColor, fontSize: 16),),],
            actions: [
              _buildDialogButton(context, _t('yes'), () => Navigator.of(context).pop(true), true),
              _buildDialogButton(context, _t('no'), () => Navigator.of(context).pop(false), false),]);
        if (!mounted) return;
        if (aceitouQuest == true) {
          await _showStyledDialog<void>(context: context, titleText: _t('system'), icon: Icons.check_circle_outline, iconColor: Colors.greenAccent,
              contentWidgets: [Text(_t('congratsPlayer'), style: const TextStyle(color: textColor, fontSize: 16),),],
              actions: [_buildDialogButton(context, _t('ok'), () => Navigator.of(context).pop(), true),]);
          if (!mounted) return;
          await _showStyledDialog<void>( context: context, titleText: _t('systemWarning'), icon: Icons.error_outline, iconColor: Colors.yellowAccent,
              contentWidgets: [Text(_t('honestWarning'), style: const TextStyle(color: Colors.yellowAccent, fontSize: 16),),],
              actions: [_buildDialogButton(context, _t('understood'), () => Navigator.of(context).pop(), true),]);
          await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({'hasCompletedIntro': true});
          if (!mounted) return;
          
          // Verificar se o usuário já completou a configuração do perfil
          DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
          bool isProfileSetupComplete = false;
          if (userDoc.exists && userDoc.data() != null) {
            final data = userDoc.data() as Map<String, dynamic>;
            isProfileSetupComplete = data['isProfileSetupComplete'] ?? false;
          }

          if (!mounted) return;
          if (!isProfileSetupComplete) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const InitialProfileSetupScreen()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } else { 
           await _showStyledDialog<void>(context: context, titleText: _t('gameOver'), icon: Icons.dangerous_outlined, iconColor: Colors.redAccent,
              contentWidgets: [Text(_t('youDied'), style: const TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),),],
              actions: [_buildDialogButton(context, _t('tryAgain'), () => Navigator.of(context).pop(), false),]);
        }} else {
        // Verificar se o usuário já completou a configuração do perfil
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        bool isProfileSetupComplete = false;
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data() as Map<String, dynamic>;
          isProfileSetupComplete = data['isProfileSetupComplete'] ?? false;
        }

        if (!mounted) return;
        if (!isProfileSetupComplete) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const InitialProfileSetupScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }} on FirebaseAuthException catch (e) { 
        print("Erro de login: $e");
        String errorMessage = _t('loginError');
        if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
          errorMessage = _t('invalidCredentials');
        } else if (e.code == 'invalid-email') {
          errorMessage = _t('invalidEmailFormat');
        }
        if (mounted) {
          _showStyledDialog(
              context: context, titleText: _t('loginFailed'), icon: Icons.error_outline_rounded, iconColor: Colors.redAccent,
              contentWidgets: [Text(errorMessage, style: const TextStyle(color: textColor))],
              actions: [_buildDialogButton(context, _t('ok'), () => Navigator.of(context).pop(), true)]);
        }
    } finally {
      if (mounted) { setState(() { _isLoading = false; });}
    }
  }

  Future<void> _forgotPassword() async { 
    _emailResetController.clear();
    final bool? confirmSend = await _showStyledDialog<bool>(
        context: context, titleText: _t('recoverKey'), icon: Icons.lock_open_rounded,
        contentWidgets: [
          Text(_t('forceOpenDungeon'), style: const TextStyle(color: textColor, fontSize: 16)),
          const SizedBox(height: 15),
          TextFormField( controller: _emailResetController, style: const TextStyle(color: textColor), keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration( labelText: _t('playerEmailLabel'), labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.email_outlined, color: accentColorBlue), filled: true, fillColor: inputBackgroundColor.withOpacity(0.6),
                 enabledBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: accentColorBlue.withOpacity(0.5), width: 1.0),),
                 focusedBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: accentColorPurple, width: 2.0),),),),],
        actions: [ _buildDialogButton(context, _t('cancel'), () => Navigator.of(context).pop(false), false),
          _buildDialogButton(context, _t('send'), () => Navigator.of(context).pop(true), true),]);
    if (confirmSend == true && _emailResetController.text.isNotEmpty) {
      setState(() { _isLoading = true; });
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailResetController.text.trim());
        if (!mounted) return;
        _showStyledDialog( context: context, titleText: _t('system'), icon: Icons.check_circle_outline_rounded, iconColor: Colors.greenAccent,
            contentWidgets: [Text(_t('keyDungeonSent'), style: const TextStyle(color: textColor))],
            actions: [_buildDialogButton(context, _t('ok'), () => Navigator.of(context).pop(), true)]);
      } on FirebaseAuthException catch (e) {
        String errorMessage = _t('passwordResetError');
        if (e.code == 'user-not-found') { errorMessage = _t('noPlayerFound');
        } else if (e.code == 'invalid-email') { errorMessage = _t('invalidEmailFormat');}
         if (!mounted) return;
        _showStyledDialog( context: context, titleText: _t('failure'), icon: Icons.error_outline_rounded, iconColor: Colors.redAccent,
            contentWidgets: [Text(errorMessage, style: const TextStyle(color: textColor))],
            actions: [_buildDialogButton(context, _t('ok'), () => Navigator.of(context).pop(), true)]);
        print("Erro ao enviar email de reset: $e");
      } finally {
         if (mounted) { setState(() { _isLoading = false; });}
      }}}

  void _signUp() { // Esta função agora é chamada
    if (mounted) {
      Navigator.push( context, MaterialPageRoute(builder: (context) => const RegisterScreen()),);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final InputDecoration inputDecoration = InputDecoration(
          filled: true, fillColor: inputBackgroundColor.withOpacity(0.6),
          labelStyle: const TextStyle(color: textColor), hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
          enabledBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: accentColorBlue.withOpacity(0.5), width: 1.0),),
          focusedBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: accentColorPurple, width: 2.0),),
          errorBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),),
          focusedErrorBorder: OutlineInputBorder( borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),),
        );

        return Scaffold(
          backgroundColor: primaryColor,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [ primaryColor, Color(0xFF050711),],),),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(_t('gymLeveling'), textAlign: TextAlign.center,
                      style: const TextStyle(color: textColor, fontSize: 36.0, fontWeight: FontWeight.bold,
                        shadows: [ Shadow(blurRadius: 10.0, color: accentColorBlue, offset: Offset(0, 0),),
                                   Shadow(blurRadius: 15.0, color: accentColorPurple, offset: Offset(0, 0),),],),),
                    const SizedBox(height: 60.0),
                    TextFormField(
                      controller: _usernameController, style: const TextStyle(color: textColor),
                      decoration: inputDecoration.copyWith( labelText: _t('playerEmail'),
                        prefixIcon: const Icon(Icons.email_outlined, color: accentColorBlue),), 
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 25.0),
                    TextFormField(
                      controller: _passwordController, style: const TextStyle(color: textColor),
                      obscureText: !_isPasswordVisible,
                      decoration: inputDecoration.copyWith( labelText: _t('dungeonKey'),
                        prefixIcon: const Icon(Icons.vpn_key_outlined, color: accentColorBlue),
                        suffixIcon: IconButton(
                          icon: Icon( _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: accentColorPurple,),
                          onPressed: () { setState(() { _isPasswordVisible = !_isPasswordVisible; });},),),),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (bool? value) {
                                  setState(() { _rememberMe = value ?? false;});
                                },
                                activeColor: accentColorPurple, checkColor: textColor,
                                side: BorderSide(color: accentColorBlue.withOpacity(0.7)),
                                visualDensity: VisualDensity.compact,
                              ),
                              Text(_t('rememberKey'), style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 13.0),),
                            ],
                          ),
                          TextButton(
                            onPressed: _isLoading ? null : _forgotPassword,
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            child: Text(_t('forgotKey'), style: const TextStyle(color: accentColorBlue, fontSize: 13.0),),),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    _isLoading
                      ? const Center(child: CircularProgressIndicator(color: accentColorPurple))
                      : Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.0),
                            gradient: const LinearGradient( colors: [accentColorBlue, accentColorPurple], begin: Alignment.centerLeft, end: Alignment.centerRight,),
                            boxShadow: [ BoxShadow( color: accentColorPurple.withOpacity(0.5), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, 3),),],),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric(vertical: 15.0), backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent, shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(30.0),),),
                            child: Text(_t('enterDungeon'), style: const TextStyle( color: textColor, fontSize: 18.0, fontWeight: FontWeight.bold,),),),),
                    const SizedBox(height: 40.0),
                    Row( mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(_t('noAccess'), style: TextStyle(color: textColor.withOpacity(0.7)),),
                        TextButton(
                          onPressed: _isLoading ? null : _signUp,
                          child: Text(_t('becomePlayer'), style: const TextStyle( color: accentColorPurple, fontWeight: FontWeight.bold, fontSize: 16.0,),),),],),
                  ],
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
    _usernameController.dispose();
    _passwordController.dispose();
    _emailResetController.dispose();
    super.dispose();
  }
}