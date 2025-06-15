// ignore_for_file: avoid_print

import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  Future<bool> getShowGlobalNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('showGlobalNotifications') ?? true;
  }

  Future<bool> getShowGuildNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('showGuildNotifications') ?? true;
  }

  Future<bool> getShowFriendNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('showFriendNotifications') ?? true;
  }

  Future<int> getRestTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('restTime') ?? 60;
  }

  Future<void> setShowGlobalNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showGlobalNotifications', value);
    await _saveToFirebase('showGlobalNotifications', value);
  }

  Future<void> setShowGuildNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showGuildNotifications', value);
    await _saveToFirebase('showGuildNotifications', value);
  }

  Future<void> setShowFriendNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showFriendNotifications', value);
    await _saveToFirebase('showFriendNotifications', value);
  }

  Future<void> setRestTime(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('restTime', value);
    await _saveToFirebase('restTime', value);
  }

  Future<void> _saveToFirebase(String key, dynamic value) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('settings')
            .doc('user_settings')
            .set({key: value}, SetOptions(merge: true));
      } catch (e) {
        print("Erro ao salvar configuração no Firebase: $e");
      }
    }
  }

  Future<void> saveAllSettings({
    required bool showGlobalNotifications,
    required bool showGuildNotifications,
    required bool showFriendNotifications,
    required int restTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showGlobalNotifications', showGlobalNotifications);
    await prefs.setBool('showGuildNotifications', showGuildNotifications);
    await prefs.setBool('showFriendNotifications', showFriendNotifications);
    await prefs.setInt('restTime', restTime);

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('settings')
            .doc('user_settings')
            .set({
          'showGlobalNotifications': showGlobalNotifications,
          'showGuildNotifications': showGuildNotifications,
          'showFriendNotifications': showFriendNotifications,
          'restTime': restTime,
        });
      } catch (e) {
        print("Erro ao salvar configurações no Firebase: $e");
      }
    }
  }

  Future<void> loadSettingsFromFirebase() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot settingsDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('settings')
            .doc('user_settings')
            .get();

        if (settingsDoc.exists) {
          final data = settingsDoc.data() as Map<String, dynamic>;
          final prefs = await SharedPreferences.getInstance();
          
          if (data.containsKey('showGlobalNotifications')) {
            await prefs.setBool('showGlobalNotifications', data['showGlobalNotifications']);
          }
          if (data.containsKey('showGuildNotifications')) {
            await prefs.setBool('showGuildNotifications', data['showGuildNotifications']);
          }
          if (data.containsKey('showFriendNotifications')) {
            await prefs.setBool('showFriendNotifications', data['showFriendNotifications']);
          }
          if (data.containsKey('restTime')) {
            await prefs.setInt('restTime', data['restTime']);
          }
        }
      } catch (e) {
        print("Erro ao carregar configurações do Firebase: $e");
      }
    }
  }
} 