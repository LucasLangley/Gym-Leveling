// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'home_screen.dart';
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/services.dart';

class InitialProfileSetupScreen extends StatefulWidget {
  const InitialProfileSetupScreen({super.key});

  @override
  State<InitialProfileSetupScreen> createState() => _InitialProfileSetupScreenState();
}

class _InitialProfileSetupScreenState extends State<InitialProfileSetupScreen> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();
  String _selectedRegion = 'América do Sul';
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _profileImageUrl;
  
  final _cloudinary = CloudinaryPublic(
    'dzs2zzlyu', 
    'Icons-Users',
    cache: false,
  );

  final List<String> _regions = [
    'América do Norte',
    'América do Sul',
    'Europa',
    'Ásia',
    'África',
    'Oceania'
  ];

  static const Color primaryColor = Color(0xFF0A0E21);
  static const Color accentColorBlue = Color(0xFF00BFFF);
  static const Color accentColorPurple = Color(0xFF8A2BE2);
  static const Color textColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        
        // Se o perfil já está completo, redirecionar para home
        if (data['isProfileSetupComplete'] == true) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
          return;
        }
        
        // Preencher campos se já existirem dados parciais
        setState(() {
          _profileImageUrl = data['profileImageUrl'];
          if (data['playerName'] != null) {
            _playerNameController.text = data['playerName'];
          }
          if (data['height'] != null) {
            _heightController.text = data['height'].toString();
          }
          if (data['weight'] != null) {
            _weightController.text = data['weight'].toString();
          }
          if (data['region'] != null) {
            _selectedRegion = data['region'];
          }
        });
      }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImage(XFile imageFile) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return response.secureUrl;
        } on CloudinaryException {
      return null;
    } catch (e) {
      return null;
    }
  }

  Widget _buildImagePreview() {
    return Container(
      height: 150,
      width: 150,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        shape: BoxShape.circle,
        border: Border.all(color: accentColorBlue.withOpacity(0.3), width: 1),
      ),
      child: _selectedImage != null
          ? ClipOval(
              child: kIsWeb
                  ? Image.network(
                      _selectedImage!.path,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : Image.file(
                      File(_selectedImage!.path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
            )
          : (_profileImageUrl != null
              ? ClipOval(
                  child: Image.network(
                    _profileImageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
              : const Icon(
                  Icons.person,
                  size: 100,
                  color: Colors.white,
                )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Configure seu Perfil',
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              const Text(
                'Qual o seu nome de jogador?',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accentColorBlue.withOpacity(0.3)),
                ),
                child: TextField(
                  controller: _playerNameController,
                  style: const TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Nome do Jogador',
                    labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  enabled: !_isLoading,
                ),
              ),
              const SizedBox(height: 20),
              
              // Seção de Foto
              const Text(
                'Escolha sua Foto',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: _isLoading ? null : _pickImage,
                  child: _buildImagePreview(),
                ),
              ),
              const SizedBox(height: 20),

              // Mensagem de aviso
              const Text(
                'Preencha seus dados de altura e peso do Jogador',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),

              // Campos de Altura e Peso
              Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accentColorBlue.withOpacity(0.3)),
                      ),
                      child: TextField(
                        controller: _heightController,
                        style: const TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Altura (ex: 1.83m)',
                          labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d{0,1}(\.\d{0,2})?')),
                        ],
                        onChanged: (value) {
                          // Validação do valor
                          if (value.isNotEmpty) {
                            // Remove o 'm' para validação
                            String heightStr = value.replaceAll('m', '');
                            double? height = double.tryParse(heightStr);
                            if (height != null) {
                              if (height < 1.0 || height > 2.5) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Altura deve estar entre 1.00m e 2.50m'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                _heightController.text = '';
                              }
                            }
                          }
                        },
                        enabled: !_isLoading,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accentColorBlue.withOpacity(0.3)),
                      ),
                      child: TextField(
                        controller: _weightController,
                        style: const TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Peso (kg)',
                          labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !_isLoading,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Seletor de Região
              const Text(
                'Sua Região',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accentColorBlue.withOpacity(0.3), width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRegion,
                    isExpanded: true,
                    dropdownColor: Colors.grey[900],
                    style: const TextStyle(color: textColor),
                    items: _regions.map((String region) {
                      return DropdownMenuItem<String>(
                        value: region,
                        child: Text(region),
                      );
                    }).toList(),
                    onChanged: _isLoading ? null : (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedRegion = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Botão de Salvar
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColorPurple,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: accentColorBlue.withOpacity(0.7), width: 1.5),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: textColor,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Salvar e Continuar',
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
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_heightController.text.isEmpty || _weightController.text.isEmpty || (_selectedImage == null && _profileImageUrl == null)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, preencha todos os campos e selecione uma foto'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Validação adicional da altura
    String heightStr = _heightController.text.replaceAll('m', '');
    double? height = double.tryParse(heightStr);
    if (height == null || height < 1.0 || height > 2.5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Altura inválida. Deve estar entre 1.00m e 2.50m'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? imageUrl;
        
        if (_selectedImage != null) {
          imageUrl = await _uploadImage(_selectedImage!);
        } else {
          imageUrl = _profileImageUrl;
        }

        if (imageUrl == null) {
          throw Exception('Falha ao fazer upload da imagem para Cloudinary');
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'playerName': _playerNameController.text.isNotEmpty ? _playerNameController.text : (user.displayName ?? 'Jogador'),
          'height': height, // Usando o valor já validado
          'weight': double.parse(_weightController.text),
          'region': _selectedRegion,
          'profileImageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'isProfileSetupComplete': true,
        }, SetOptions(merge: true));

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}