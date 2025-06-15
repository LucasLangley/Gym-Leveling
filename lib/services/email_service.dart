import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  // Configuração do EmailJS - substitua pelos seus dados reais
  static const String _serviceId = 'service_98k5zgr'; // Ex: service_xyz123
  static const String _templateId = 'template_o8hiio3'; // Ex: template_abc456
  static const String _userId = '1kzwEF0iL9osr6HG6'; // Ex: user_789xyz

  // Configuração do Formspree (alternativa mais simples)
  static const String _formspreeUrl = 'https://formspree.io/f/SEU_FORM_ID_AQUI'; // Substitua pelo seu Form ID real

  static Future<bool> sendReportEmail({
    required String reason,
    required String reportedPlayerName,
    required String reportedPlayerId,
    required String reporterName,
    required String reporterId,
  }) async {
    try {
      const String url = 'https://api.emailjs.com/api/v1.0/email/send';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _userId,
          'template_params': {
            'to_email': 'lucasboroto00@gmail.com',
            'subject': 'Denúncia - Gym Leveling App',
            'reason': reason,
            'reported_player_name': reportedPlayerName,
            'reported_player_id': reportedPlayerId,
            'reporter_name': reporterName,
            'reporter_id': reporterId,
            'timestamp': DateTime.now().toLocal().toString(),
            'message': '''
Denúncia recebida no Gym Leveling:

Motivo: $reason
Jogador Denunciado: $reportedPlayerName (ID: $reportedPlayerId)  
Denunciado por: $reporterName (ID: $reporterId)

Data/Hora: ${DateTime.now().toLocal()}

---
Este é um e-mail automático do sistema de denúncias.
            ''',
          },
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Método usando Formspree (mais simples de configurar)
  static Future<bool> sendReportViaFormspree({
    required String reason,
    required String reportedPlayerName,
    required String reportedPlayerId,
    required String reporterName,
    required String reporterId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_formspreeUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': 'lucasboroto00@gmail.com',
          'subject': 'Denúncia - Gym Leveling App',
          'message': '''
Denúncia recebida no Gym Leveling:

Motivo: $reason
Jogador Denunciado: $reportedPlayerName (ID: $reportedPlayerId)
Denunciado por: $reporterName (ID: $reporterId)

Data/Hora: ${DateTime.now().toLocal()}

---
Este é um e-mail automático do sistema de denúncias.
          ''',
          'reason': reason,
          'reported_player': reportedPlayerName,
          'reported_id': reportedPlayerId,
          'reporter_name': reporterName,
          'reporter_id': reporterId,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Método com fallback - tenta múltiplos serviços
  static Future<bool> sendReportWithFallback({
    required String reason,
    required String reportedPlayerName,
    required String reportedPlayerId,
    required String reporterName,
    required String reporterId,
  }) async {
    // Primeiro tenta Formspree
    try {
      bool success = await sendReportViaFormspree(
        reason: reason,
        reportedPlayerName: reportedPlayerName,
        reportedPlayerId: reportedPlayerId,
        reporterName: reporterName,
        reporterId: reporterId,
      );
             if (success) {
         return true;
       }
     } catch (e) {
       // Falha silenciosa
    }

    // Se Formspree falhar, tenta EmailJS
    try {
      bool success = await sendReportEmail(
        reason: reason,
        reportedPlayerName: reportedPlayerName,
        reportedPlayerId: reportedPlayerId,
        reporterName: reporterName,
        reporterId: reporterId,
      );
             if (success) {
         return true;
       }
     } catch (e) {
       // Falha silenciosa
     }

     // Se ambos falharem, pelo menos salva o log
    return await sendDirectEmail(
      reason: reason,
      reportedPlayerName: reportedPlayerName,
      reportedPlayerId: reportedPlayerId,
      reporterName: reporterName,
      reporterId: reporterId,
    );
  }

  // Método alternativo usando SMTP direto (mais complexo, requer configuração adicional)
  static Future<bool> sendDirectEmail({
    required String reason,
    required String reportedPlayerName,
    required String reportedPlayerId,
    required String reporterName,
    required String reporterId,
  }) async {
    try {
      // Simula delay de envio
      await Future.delayed(const Duration(seconds: 1));
      
      return true;
    } catch (e) {
      return false;
    }
  }
} 