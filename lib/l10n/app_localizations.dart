import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gym Leveling'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In pt, this message translates to:
  /// **'CONFIGURAÇÕES'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In pt, this message translates to:
  /// **'Notificações exibidas em notificações recentes:'**
  String get notifications;

  /// No description provided for @globalNotifications.
  ///
  /// In pt, this message translates to:
  /// **'Global'**
  String get globalNotifications;

  /// No description provided for @guildNotifications.
  ///
  /// In pt, this message translates to:
  /// **'Guilda'**
  String get guildNotifications;

  /// No description provided for @friendNotifications.
  ///
  /// In pt, this message translates to:
  /// **'Amigos'**
  String get friendNotifications;

  /// No description provided for @restTimeDefault.
  ///
  /// In pt, this message translates to:
  /// **'Tempo de descanso padrão (segundos):'**
  String get restTimeDefault;

  /// No description provided for @language.
  ///
  /// In pt, this message translates to:
  /// **'Idioma:'**
  String get language;

  /// No description provided for @portuguese.
  ///
  /// In pt, this message translates to:
  /// **'Português'**
  String get portuguese;

  /// No description provided for @english.
  ///
  /// In pt, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @logout.
  ///
  /// In pt, this message translates to:
  /// **'SAIR DA CONTA'**
  String get logout;

  /// No description provided for @logoutConfirmation.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Logout'**
  String get logoutConfirmation;

  /// No description provided for @logoutConfirmationMessage.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja sair da sua conta?'**
  String get logoutConfirmationMessage;

  /// No description provided for @logoutButton.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get logoutButton;

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @error.
  ///
  /// In pt, this message translates to:
  /// **'Erro'**
  String get error;

  /// No description provided for @logoutError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao fazer logout: {error}'**
  String logoutError(Object error);

  /// No description provided for @ok.
  ///
  /// In pt, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @login.
  ///
  /// In pt, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @email.
  ///
  /// In pt, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get password;

  /// No description provided for @loginButton.
  ///
  /// In pt, this message translates to:
  /// **'ENTRAR'**
  String get loginButton;

  /// No description provided for @register.
  ///
  /// In pt, this message translates to:
  /// **'CADASTRAR'**
  String get register;

  /// No description provided for @forgotPassword.
  ///
  /// In pt, this message translates to:
  /// **'Esqueceu a senha?'**
  String get forgotPassword;

  /// No description provided for @home.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get profile;

  /// No description provided for @workouts.
  ///
  /// In pt, this message translates to:
  /// **'Treinos'**
  String get workouts;

  /// No description provided for @social.
  ///
  /// In pt, this message translates to:
  /// **'Social'**
  String get social;

  /// No description provided for @loading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando...'**
  String get loading;

  /// No description provided for @success.
  ///
  /// In pt, this message translates to:
  /// **'Sucesso'**
  String get success;

  /// No description provided for @yes.
  ///
  /// In pt, this message translates to:
  /// **'Sim'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get no;

  /// No description provided for @save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In pt, this message translates to:
  /// **'Deletar'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @back.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get back;

  /// No description provided for @next.
  ///
  /// In pt, this message translates to:
  /// **'Próximo'**
  String get next;

  /// No description provided for @finish.
  ///
  /// In pt, this message translates to:
  /// **'Finalizar'**
  String get finish;

  /// No description provided for @search.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar'**
  String get search;

  /// No description provided for @level.
  ///
  /// In pt, this message translates to:
  /// **'Nível'**
  String get level;

  /// No description provided for @experience.
  ///
  /// In pt, this message translates to:
  /// **'Experiência'**
  String get experience;

  /// No description provided for @points.
  ///
  /// In pt, this message translates to:
  /// **'Pontos'**
  String get points;

  /// No description provided for @player.
  ///
  /// In pt, this message translates to:
  /// **'Jogador'**
  String get player;

  /// No description provided for @none.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma'**
  String get none;

  /// No description provided for @title.
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get title;

  /// No description provided for @reward.
  ///
  /// In pt, this message translates to:
  /// **'Recompensa'**
  String get reward;

  /// No description provided for @gymLeveling.
  ///
  /// In pt, this message translates to:
  /// **'GYM LEVELING'**
  String get gymLeveling;

  /// No description provided for @playerEmail.
  ///
  /// In pt, this message translates to:
  /// **'E-mail do Jogador'**
  String get playerEmail;

  /// No description provided for @dungeonKey.
  ///
  /// In pt, this message translates to:
  /// **'Chave da Dungeon (Senha)'**
  String get dungeonKey;

  /// No description provided for @rememberKey.
  ///
  /// In pt, this message translates to:
  /// **'Guardar chave da Dungeon'**
  String get rememberKey;

  /// No description provided for @forgotKey.
  ///
  /// In pt, this message translates to:
  /// **'Esqueci minha chave'**
  String get forgotKey;

  /// No description provided for @enterDungeon.
  ///
  /// In pt, this message translates to:
  /// **'ENTRAR NA DUNGEON'**
  String get enterDungeon;

  /// No description provided for @noAccess.
  ///
  /// In pt, this message translates to:
  /// **'Não tem acesso? '**
  String get noAccess;

  /// No description provided for @becomePlayer.
  ///
  /// In pt, this message translates to:
  /// **'Se tornar um Jogador'**
  String get becomePlayer;

  /// No description provided for @missingItems.
  ///
  /// In pt, this message translates to:
  /// **'ITENS FALTANDO!'**
  String get missingItems;

  /// No description provided for @fillEmailPassword.
  ///
  /// In pt, this message translates to:
  /// **'Por favor, preencha o e-mail e a Chave da Dungeon.'**
  String get fillEmailPassword;

  /// No description provided for @newMission.
  ///
  /// In pt, this message translates to:
  /// **'Nova Missão'**
  String get newMission;

  /// No description provided for @secretMission.
  ///
  /// In pt, this message translates to:
  /// **'Você recebeu a Missão Secreta \"Coragem do Fraco\".'**
  String get secretMission;

  /// No description provided for @heartWarning.
  ///
  /// In pt, this message translates to:
  /// **'Seu coração irá parar em 0.02 segundos se você não ceitá-la.'**
  String get heartWarning;

  /// No description provided for @acceptMission.
  ///
  /// In pt, this message translates to:
  /// **'Deseja aceitar?'**
  String get acceptMission;

  /// No description provided for @system.
  ///
  /// In pt, this message translates to:
  /// **'Sistema'**
  String get system;

  /// No description provided for @congratsPlayer.
  ///
  /// In pt, this message translates to:
  /// **'Parabéns, você se tornou um Jogador!'**
  String get congratsPlayer;

  /// No description provided for @systemWarning.
  ///
  /// In pt, this message translates to:
  /// **'Aviso do Sistema'**
  String get systemWarning;

  /// No description provided for @honestWarning.
  ///
  /// In pt, this message translates to:
  /// **'Seja honesto com o sistema, caso contrário, enfrentará consequências severas.'**
  String get honestWarning;

  /// No description provided for @understood.
  ///
  /// In pt, this message translates to:
  /// **'Entendido'**
  String get understood;

  /// No description provided for @gameOver.
  ///
  /// In pt, this message translates to:
  /// **'Fim de Jogo'**
  String get gameOver;

  /// No description provided for @youDied.
  ///
  /// In pt, this message translates to:
  /// **'Você morreu.'**
  String get youDied;

  /// No description provided for @tryAgain.
  ///
  /// In pt, this message translates to:
  /// **'Tentar Novamente'**
  String get tryAgain;

  /// No description provided for @loginFailed.
  ///
  /// In pt, this message translates to:
  /// **'Falha no Login'**
  String get loginFailed;

  /// No description provided for @invalidCredentials.
  ///
  /// In pt, this message translates to:
  /// **'E-mail ou Chave da Dungeon inválidos.'**
  String get invalidCredentials;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In pt, this message translates to:
  /// **'O formato do e-mail é inválido.'**
  String get invalidEmailFormat;

  /// No description provided for @loginError.
  ///
  /// In pt, this message translates to:
  /// **'Ocorreu um erro ao tentar fazer login.'**
  String get loginError;

  /// No description provided for @recoverKey.
  ///
  /// In pt, this message translates to:
  /// **'Recuperar Chave'**
  String get recoverKey;

  /// No description provided for @forceOpenDungeon.
  ///
  /// In pt, this message translates to:
  /// **'Forçando a abertura da dungeon, insira o e-mail do Jogador para recuperação da chave:'**
  String get forceOpenDungeon;

  /// No description provided for @playerEmailLabel.
  ///
  /// In pt, this message translates to:
  /// **'E-mail do Jogador'**
  String get playerEmailLabel;

  /// No description provided for @send.
  ///
  /// In pt, this message translates to:
  /// **'Enviar'**
  String get send;

  /// No description provided for @keyDungeonSent.
  ///
  /// In pt, this message translates to:
  /// **'Chave da Dungeon enviada para o e-mail informado!'**
  String get keyDungeonSent;

  /// No description provided for @passwordResetError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao enviar e-mail de recuperação.'**
  String get passwordResetError;

  /// No description provided for @noPlayerFound.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum jogador encontrado com este e-mail.'**
  String get noPlayerFound;

  /// No description provided for @failure.
  ///
  /// In pt, this message translates to:
  /// **'Falha'**
  String get failure;

  /// No description provided for @becomePlayerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Se Tornar um Jogador'**
  String get becomePlayerTitle;

  /// No description provided for @foundDoubleDungeon.
  ///
  /// In pt, this message translates to:
  /// **'VOCÊ ENCONTROU UMA DUNGEON DUPLA!'**
  String get foundDoubleDungeon;

  /// No description provided for @createAccount.
  ///
  /// In pt, this message translates to:
  /// **'Criar Conta'**
  String get createAccount;

  /// No description provided for @name.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get name;

  /// No description provided for @confirmPassword.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Senha'**
  String get confirmPassword;

  /// No description provided for @confirmDungeonKey.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Chave da Dungeon'**
  String get confirmDungeonKey;

  /// No description provided for @forceOpen.
  ///
  /// In pt, this message translates to:
  /// **'FORÇAR ABERTURA'**
  String get forceOpen;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In pt, this message translates to:
  /// **'Já tem uma conta? '**
  String get alreadyHaveAccount;

  /// No description provided for @loginHere.
  ///
  /// In pt, this message translates to:
  /// **'Faça login aqui'**
  String get loginHere;

  /// No description provided for @fillAllFields.
  ///
  /// In pt, this message translates to:
  /// **'Por favor, preencha todos os campos.'**
  String get fillAllFields;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In pt, this message translates to:
  /// **'Por favor, insira seu e-mail'**
  String get pleaseEnterEmail;

  /// No description provided for @enterValidEmail.
  ///
  /// In pt, this message translates to:
  /// **'Insira um e-mail válido'**
  String get enterValidEmail;

  /// No description provided for @passwordMinLength.
  ///
  /// In pt, this message translates to:
  /// **'A senha deve ter pelo menos 6 caracteres'**
  String get passwordMinLength;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In pt, this message translates to:
  /// **'Por favor, confirme sua senha'**
  String get pleaseConfirmPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não coincidem.'**
  String get passwordMismatch;

  /// No description provided for @registrationError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao criar conta'**
  String get registrationError;

  /// No description provided for @registrationFailed.
  ///
  /// In pt, this message translates to:
  /// **'Falha no Registro'**
  String get registrationFailed;

  /// No description provided for @emailInUse.
  ///
  /// In pt, this message translates to:
  /// **'Este e-mail já está em uso por outro Jogador.'**
  String get emailInUse;

  /// No description provided for @weakPassword.
  ///
  /// In pt, this message translates to:
  /// **'A Chave da Dungeon é muito fraca.'**
  String get weakPassword;

  /// No description provided for @doubleDungeon.
  ///
  /// In pt, this message translates to:
  /// **'Dungeon Dupla!'**
  String get doubleDungeon;

  /// No description provided for @doubleDungeonMessage.
  ///
  /// In pt, this message translates to:
  /// **'Jogador forçou a abertura da Dungeon Dupla!\nPrepare-se para o login.'**
  String get doubleDungeonMessage;

  /// No description provided for @toLogin.
  ///
  /// In pt, this message translates to:
  /// **'Para o Login!'**
  String get toLogin;

  /// No description provided for @criticalError.
  ///
  /// In pt, this message translates to:
  /// **'Erro Crítico'**
  String get criticalError;

  /// No description provided for @profileSetupError.
  ///
  /// In pt, this message translates to:
  /// **'Houve um problema ao configurar seu perfil. Por favor, tente fazer login ou contate o suporte se o problema persistir.'**
  String get profileSetupError;

  /// No description provided for @welcomePlayer.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo, Jogador!'**
  String get welcomePlayer;

  /// No description provided for @currentLevel.
  ///
  /// In pt, this message translates to:
  /// **'Nível Atual'**
  String get currentLevel;

  /// No description provided for @totalExp.
  ///
  /// In pt, this message translates to:
  /// **'EXP Total'**
  String get totalExp;

  /// No description provided for @dailyMissions.
  ///
  /// In pt, this message translates to:
  /// **'Missões Diárias'**
  String get dailyMissions;

  /// No description provided for @achievements.
  ///
  /// In pt, this message translates to:
  /// **'Conquistas'**
  String get achievements;

  /// No description provided for @statistics.
  ///
  /// In pt, this message translates to:
  /// **'Estatísticas'**
  String get statistics;

  /// No description provided for @recentActivity.
  ///
  /// In pt, this message translates to:
  /// **'Atividade Recente'**
  String get recentActivity;

  /// No description provided for @todaysWorkout.
  ///
  /// In pt, this message translates to:
  /// **'Treino de Hoje'**
  String get todaysWorkout;

  /// No description provided for @friends.
  ///
  /// In pt, this message translates to:
  /// **'Amigos'**
  String get friends;

  /// No description provided for @guild.
  ///
  /// In pt, this message translates to:
  /// **'Guilda'**
  String get guild;

  /// No description provided for @shop.
  ///
  /// In pt, this message translates to:
  /// **'Loja'**
  String get shop;

  /// No description provided for @inventory.
  ///
  /// In pt, this message translates to:
  /// **'Inventário'**
  String get inventory;

  /// No description provided for @auraTotal.
  ///
  /// In pt, this message translates to:
  /// **'AURA TOTAL'**
  String get auraTotal;

  /// No description provided for @characterClass.
  ///
  /// In pt, this message translates to:
  /// **'CLASSE'**
  String get characterClass;

  /// No description provided for @titleLabel.
  ///
  /// In pt, this message translates to:
  /// **'TÍTULO'**
  String get titleLabel;

  /// No description provided for @hp.
  ///
  /// In pt, this message translates to:
  /// **'HP'**
  String get hp;

  /// No description provided for @mp.
  ///
  /// In pt, this message translates to:
  /// **'MP'**
  String get mp;

  /// No description provided for @exp.
  ///
  /// In pt, this message translates to:
  /// **'EXP'**
  String get exp;

  /// No description provided for @incredible.
  ///
  /// In pt, this message translates to:
  /// **'INCRÍVEL!'**
  String get incredible;

  /// No description provided for @noMissionsSelected.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma missão diária selecionada.'**
  String get noMissionsSelected;

  /// No description provided for @goToMissionsScreen.
  ///
  /// In pt, this message translates to:
  /// **'Vá para a tela de Missões (ícone de prancheta abaixo) para escolher suas aventuras diárias!'**
  String get goToMissionsScreen;

  /// No description provided for @rewardCollected.
  ///
  /// In pt, this message translates to:
  /// **'RECOMPENSA COLETADA'**
  String get rewardCollected;

  /// No description provided for @collectRewards.
  ///
  /// In pt, this message translates to:
  /// **'COLETAR RECOMPENSAS'**
  String get collectRewards;

  /// No description provided for @attentionPenalty.
  ///
  /// In pt, this message translates to:
  /// **'ATENÇÃO: Não completar as Missões Diárias e não coletar a recompensa resultará em penalidades!'**
  String get attentionPenalty;

  /// No description provided for @viewFront.
  ///
  /// In pt, this message translates to:
  /// **'VER FRENTE'**
  String get viewFront;

  /// No description provided for @viewBack.
  ///
  /// In pt, this message translates to:
  /// **'VER COSTAS'**
  String get viewBack;

  /// No description provided for @errorSavingMission.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar progresso da missão.'**
  String get errorSavingMission;

  /// No description provided for @rewardsAlreadyCollected.
  ///
  /// In pt, this message translates to:
  /// **'Você já coletou as recompensas da missão diária de hoje.'**
  String get rewardsAlreadyCollected;

  /// No description provided for @completeAllMissions.
  ///
  /// In pt, this message translates to:
  /// **'Você precisa completar TODAS as missões diárias selecionadas para coletar a recompensa.'**
  String get completeAllMissions;

  /// No description provided for @needLoginRewards.
  ///
  /// In pt, this message translates to:
  /// **'Você precisa estar logado para coletar recompensas.'**
  String get needLoginRewards;

  /// No description provided for @rewardRegistrationError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível registrar a recompensa. Tente novamente.'**
  String get rewardRegistrationError;

  /// No description provided for @playerProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil do Jogador'**
  String get playerProfile;

  /// No description provided for @editProfile.
  ///
  /// In pt, this message translates to:
  /// **'Editar Perfil'**
  String get editProfile;

  /// No description provided for @profileStats.
  ///
  /// In pt, this message translates to:
  /// **'Estatísticas do Perfil'**
  String get profileStats;

  /// No description provided for @strength.
  ///
  /// In pt, this message translates to:
  /// **'Força'**
  String get strength;

  /// No description provided for @endurance.
  ///
  /// In pt, this message translates to:
  /// **'Resistência'**
  String get endurance;

  /// No description provided for @agility.
  ///
  /// In pt, this message translates to:
  /// **'Agilidade'**
  String get agility;

  /// No description provided for @intelligence.
  ///
  /// In pt, this message translates to:
  /// **'Inteligência'**
  String get intelligence;

  /// No description provided for @luck.
  ///
  /// In pt, this message translates to:
  /// **'Sorte'**
  String get luck;

  /// No description provided for @height.
  ///
  /// In pt, this message translates to:
  /// **'Altura'**
  String get height;

  /// No description provided for @weight.
  ///
  /// In pt, this message translates to:
  /// **'Peso'**
  String get weight;

  /// No description provided for @age.
  ///
  /// In pt, this message translates to:
  /// **'Idade'**
  String get age;

  /// No description provided for @joinDate.
  ///
  /// In pt, this message translates to:
  /// **'Data de Ingresso'**
  String get joinDate;

  /// No description provided for @totalWorkouts.
  ///
  /// In pt, this message translates to:
  /// **'Total de Treinos'**
  String get totalWorkouts;

  /// No description provided for @favoriteExercise.
  ///
  /// In pt, this message translates to:
  /// **'Exercício Favorito'**
  String get favoriteExercise;

  /// No description provided for @badges.
  ///
  /// In pt, this message translates to:
  /// **'Medalhas'**
  String get badges;

  /// No description provided for @personalRecords.
  ///
  /// In pt, this message translates to:
  /// **'Recordes Pessoais'**
  String get personalRecords;

  /// No description provided for @change.
  ///
  /// In pt, this message translates to:
  /// **'Alterar'**
  String get change;

  /// No description provided for @tapPhotoToChange.
  ///
  /// In pt, this message translates to:
  /// **'Toque na foto para alterar'**
  String get tapPhotoToChange;

  /// No description provided for @heightWeight.
  ///
  /// In pt, this message translates to:
  /// **'Altura/Peso'**
  String get heightWeight;

  /// No description provided for @biography.
  ///
  /// In pt, this message translates to:
  /// **'Biografia'**
  String get biography;

  /// No description provided for @biographyTitle.
  ///
  /// In pt, this message translates to:
  /// **'BIOGRAFIA'**
  String get biographyTitle;

  /// No description provided for @availablePoints.
  ///
  /// In pt, this message translates to:
  /// **'Pontos Disponíveis'**
  String get availablePoints;

  /// No description provided for @unsavedChanges.
  ///
  /// In pt, this message translates to:
  /// **'Você tem alterações não salvas'**
  String get unsavedChanges;

  /// No description provided for @saveAttributes.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR ATRIBUTOS'**
  String get saveAttributes;

  /// No description provided for @errorSavingAttributes.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar atributos. Tente novamente.'**
  String get errorSavingAttributes;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In pt, this message translates to:
  /// **'Alterar Foto de Perfil'**
  String get changeProfilePhoto;

  /// No description provided for @chooseNewPhoto.
  ///
  /// In pt, this message translates to:
  /// **'Escolha uma nova foto de perfil:'**
  String get chooseNewPhoto;

  /// No description provided for @saving.
  ///
  /// In pt, this message translates to:
  /// **'Salvando...'**
  String get saving;

  /// No description provided for @uploadingImage.
  ///
  /// In pt, this message translates to:
  /// **'Fazendo upload da imagem...'**
  String get uploadingImage;

  /// No description provided for @photoUpdatedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Foto de perfil atualizada com sucesso!'**
  String get photoUpdatedSuccess;

  /// No description provided for @uploadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao fazer upload da imagem. Tente novamente.'**
  String get uploadError;

  /// No description provided for @savePhotoError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar foto'**
  String get savePhotoError;

  /// No description provided for @editBiography.
  ///
  /// In pt, this message translates to:
  /// **'Editar Biografia'**
  String get editBiography;

  /// No description provided for @tellAboutYourself.
  ///
  /// In pt, this message translates to:
  /// **'Conte um pouco sobre você:'**
  String get tellAboutYourself;

  /// No description provided for @writeBiographyHere.
  ///
  /// In pt, this message translates to:
  /// **'Escreva sua biografia aqui...'**
  String get writeBiographyHere;

  /// No description provided for @characters.
  ///
  /// In pt, this message translates to:
  /// **'caracteres'**
  String get characters;

  /// No description provided for @biographyTooLong.
  ///
  /// In pt, this message translates to:
  /// **'Biografia muito longa. Máximo de'**
  String get biographyTooLong;

  /// No description provided for @biographyUpdatedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Biografia atualizada com sucesso!'**
  String get biographyUpdatedSuccess;

  /// No description provided for @errorSavingBiography.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar biografia'**
  String get errorSavingBiography;

  /// No description provided for @editPhysicalInfo.
  ///
  /// In pt, this message translates to:
  /// **'Editar Informações Físicas'**
  String get editPhysicalInfo;

  /// No description provided for @updatePhysicalInfo.
  ///
  /// In pt, this message translates to:
  /// **'Atualize suas informações físicas:'**
  String get updatePhysicalInfo;

  /// No description provided for @heightM.
  ///
  /// In pt, this message translates to:
  /// **'Altura (m)'**
  String get heightM;

  /// No description provided for @weightKg.
  ///
  /// In pt, this message translates to:
  /// **'Peso (kg)'**
  String get weightKg;

  /// No description provided for @physicalInfoUpdatedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Informações físicas atualizadas com sucesso!'**
  String get physicalInfoUpdatedSuccess;

  /// No description provided for @errorSavingChanges.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar alterações'**
  String get errorSavingChanges;

  /// No description provided for @head.
  ///
  /// In pt, this message translates to:
  /// **'Cabeça'**
  String get head;

  /// No description provided for @chest.
  ///
  /// In pt, this message translates to:
  /// **'Peitoral'**
  String get chest;

  /// No description provided for @rightHand.
  ///
  /// In pt, this message translates to:
  /// **'Mão Direita'**
  String get rightHand;

  /// No description provided for @legs.
  ///
  /// In pt, this message translates to:
  /// **'Pernas'**
  String get legs;

  /// No description provided for @feet.
  ///
  /// In pt, this message translates to:
  /// **'Pés'**
  String get feet;

  /// No description provided for @accessoryL.
  ///
  /// In pt, this message translates to:
  /// **'Acessório E.'**
  String get accessoryL;

  /// No description provided for @ears.
  ///
  /// In pt, this message translates to:
  /// **'Orelhas'**
  String get ears;

  /// No description provided for @necklace.
  ///
  /// In pt, this message translates to:
  /// **'Colar'**
  String get necklace;

  /// No description provided for @leftHand.
  ///
  /// In pt, this message translates to:
  /// **'Mão Esquerda'**
  String get leftHand;

  /// No description provided for @face.
  ///
  /// In pt, this message translates to:
  /// **'Rosto'**
  String get face;

  /// No description provided for @bracelet.
  ///
  /// In pt, this message translates to:
  /// **'Bracelete'**
  String get bracelet;

  /// No description provided for @accessoryR.
  ///
  /// In pt, this message translates to:
  /// **'Acessório D.'**
  String get accessoryR;

  /// No description provided for @rank.
  ///
  /// In pt, this message translates to:
  /// **'Rank'**
  String get rank;

  /// No description provided for @titleAspirante.
  ///
  /// In pt, this message translates to:
  /// **'Aspirante'**
  String get titleAspirante;

  /// No description provided for @titleInicianteForca.
  ///
  /// In pt, this message translates to:
  /// **'Iniciante da Força'**
  String get titleInicianteForca;

  /// No description provided for @titleResistente.
  ///
  /// In pt, this message translates to:
  /// **'Resistente'**
  String get titleResistente;

  /// No description provided for @titleVeloz.
  ///
  /// In pt, this message translates to:
  /// **'Veloz'**
  String get titleVeloz;

  /// No description provided for @titleSabio.
  ///
  /// In pt, this message translates to:
  /// **'Sábio'**
  String get titleSabio;

  /// No description provided for @titleObservador.
  ///
  /// In pt, this message translates to:
  /// **'Observador'**
  String get titleObservador;

  /// No description provided for @titleGuerreiro.
  ///
  /// In pt, this message translates to:
  /// **'Guerreiro'**
  String get titleGuerreiro;

  /// No description provided for @titleTanque.
  ///
  /// In pt, this message translates to:
  /// **'Tanque'**
  String get titleTanque;

  /// No description provided for @titleAssassino.
  ///
  /// In pt, this message translates to:
  /// **'Assassino'**
  String get titleAssassino;

  /// No description provided for @titleMago.
  ///
  /// In pt, this message translates to:
  /// **'Mago'**
  String get titleMago;

  /// No description provided for @titleExplorador.
  ///
  /// In pt, this message translates to:
  /// **'Explorador'**
  String get titleExplorador;

  /// No description provided for @titleLendaForca.
  ///
  /// In pt, this message translates to:
  /// **'Lenda da Força'**
  String get titleLendaForca;

  /// No description provided for @titleImortal.
  ///
  /// In pt, this message translates to:
  /// **'Imortal'**
  String get titleImortal;

  /// No description provided for @titleSombra.
  ///
  /// In pt, this message translates to:
  /// **'Sombra'**
  String get titleSombra;

  /// No description provided for @titleArquiMago.
  ///
  /// In pt, this message translates to:
  /// **'Arqui-Mago'**
  String get titleArquiMago;

  /// No description provided for @titleOnividente.
  ///
  /// In pt, this message translates to:
  /// **'Onividente'**
  String get titleOnividente;

  /// No description provided for @classPaladino.
  ///
  /// In pt, this message translates to:
  /// **'Paladino'**
  String get classPaladino;

  /// No description provided for @classNecromante.
  ///
  /// In pt, this message translates to:
  /// **'Necromante'**
  String get classNecromante;

  /// No description provided for @classBerserker.
  ///
  /// In pt, this message translates to:
  /// **'Berserker'**
  String get classBerserker;

  /// No description provided for @classArcano.
  ///
  /// In pt, this message translates to:
  /// **'Arcano'**
  String get classArcano;

  /// No description provided for @classRanger.
  ///
  /// In pt, this message translates to:
  /// **'Ranger'**
  String get classRanger;

  /// No description provided for @classLordeGuerra.
  ///
  /// In pt, this message translates to:
  /// **'Lorde da Guerra'**
  String get classLordeGuerra;

  /// No description provided for @classMestreArcano.
  ///
  /// In pt, this message translates to:
  /// **'Mestre Arcano'**
  String get classMestreArcano;

  /// No description provided for @classSombraLetal.
  ///
  /// In pt, this message translates to:
  /// **'Sombra Letal'**
  String get classSombraLetal;

  /// No description provided for @itemElmoFerro.
  ///
  /// In pt, this message translates to:
  /// **'Elmo de Ferro'**
  String get itemElmoFerro;

  /// No description provided for @itemCotaMalha.
  ///
  /// In pt, this message translates to:
  /// **'Cota de Malha Reforçada'**
  String get itemCotaMalha;

  /// No description provided for @itemLaminaAgil.
  ///
  /// In pt, this message translates to:
  /// **'Lâmina Ágil'**
  String get itemLaminaAgil;

  /// No description provided for @itemBotasSombrias.
  ///
  /// In pt, this message translates to:
  /// **'Botas Sombrias'**
  String get itemBotasSombrias;

  /// No description provided for @itemColarMonarca.
  ///
  /// In pt, this message translates to:
  /// **'Colar do Monarca'**
  String get itemColarMonarca;

  /// No description provided for @itemAnelPoder.
  ///
  /// In pt, this message translates to:
  /// **'Anel de Poder'**
  String get itemAnelPoder;

  /// No description provided for @createNewGuild.
  ///
  /// In pt, this message translates to:
  /// **'CRIAR NOVA GUILDA'**
  String get createNewGuild;

  /// No description provided for @errorLoadingInventory.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar inventário'**
  String get errorLoadingInventory;

  /// No description provided for @errorSelectingImage.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao selecionar imagem'**
  String get errorSelectingImage;

  /// No description provided for @heightBetween.
  ///
  /// In pt, this message translates to:
  /// **'Altura deve estar entre 1.00m e 2.50m'**
  String get heightBetween;

  /// No description provided for @fillAllFieldsSelectPhoto.
  ///
  /// In pt, this message translates to:
  /// **'Por favor, preencha todos os campos e selecione uma foto'**
  String get fillAllFieldsSelectPhoto;

  /// No description provided for @invalidHeight.
  ///
  /// In pt, this message translates to:
  /// **'Altura inválida. Deve estar entre 1.00m e 2.50m'**
  String get invalidHeight;

  /// No description provided for @errorSavingProfile.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar perfil'**
  String get errorSavingProfile;

  /// No description provided for @noUserLoggedAchievements.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum usuário logado para carregar conquistas.'**
  String get noUserLoggedAchievements;

  /// No description provided for @achievementsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar status das conquistas do usuário'**
  String get achievementsLoadError;

  /// No description provided for @noAchievementsSystem.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma conquista definida no sistema.'**
  String get noAchievementsSystem;

  /// No description provided for @workoutScreen.
  ///
  /// In pt, this message translates to:
  /// **'Tela de Treino'**
  String get workoutScreen;

  /// No description provided for @startWorkout.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar Treino'**
  String get startWorkout;

  /// No description provided for @endWorkout.
  ///
  /// In pt, this message translates to:
  /// **'Finalizar Treino'**
  String get endWorkout;

  /// No description provided for @pauseWorkout.
  ///
  /// In pt, this message translates to:
  /// **'Pausar Treino'**
  String get pauseWorkout;

  /// No description provided for @resumeWorkout.
  ///
  /// In pt, this message translates to:
  /// **'Retomar Treino'**
  String get resumeWorkout;

  /// No description provided for @currentExercise.
  ///
  /// In pt, this message translates to:
  /// **'Exercício Atual'**
  String get currentExercise;

  /// No description provided for @sets.
  ///
  /// In pt, this message translates to:
  /// **'Séries'**
  String get sets;

  /// No description provided for @reps.
  ///
  /// In pt, this message translates to:
  /// **'Repetições'**
  String get reps;

  /// No description provided for @restTime.
  ///
  /// In pt, this message translates to:
  /// **'Tempo de Descanso'**
  String get restTime;

  /// No description provided for @nextExercise.
  ///
  /// In pt, this message translates to:
  /// **'Próximo Exercício'**
  String get nextExercise;

  /// No description provided for @previousExercise.
  ///
  /// In pt, this message translates to:
  /// **'Exercício Anterior'**
  String get previousExercise;

  /// No description provided for @addSet.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Série'**
  String get addSet;

  /// No description provided for @removeSet.
  ///
  /// In pt, this message translates to:
  /// **'Remover Série'**
  String get removeSet;

  /// No description provided for @workoutCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Treino Concluído!'**
  String get workoutCompleted;

  /// No description provided for @expGained.
  ///
  /// In pt, this message translates to:
  /// **'EXP Ganho'**
  String get expGained;

  /// No description provided for @timeElapsed.
  ///
  /// In pt, this message translates to:
  /// **'Tempo Decorrido'**
  String get timeElapsed;

  /// No description provided for @exercisesCompleted.
  ///
  /// In pt, this message translates to:
  /// **'Exercícios Completos'**
  String get exercisesCompleted;

  /// No description provided for @socialHub.
  ///
  /// In pt, this message translates to:
  /// **'Central Social'**
  String get socialHub;

  /// No description provided for @friendsList.
  ///
  /// In pt, this message translates to:
  /// **'Lista de Amigos'**
  String get friendsList;

  /// No description provided for @friendRequests.
  ///
  /// In pt, this message translates to:
  /// **'Solicitações de Amizade'**
  String get friendRequests;

  /// No description provided for @findFriends.
  ///
  /// In pt, this message translates to:
  /// **'Encontrar Amigos'**
  String get findFriends;

  /// No description provided for @guildInfo.
  ///
  /// In pt, this message translates to:
  /// **'Informações da Guilda'**
  String get guildInfo;

  /// No description provided for @joinGuild.
  ///
  /// In pt, this message translates to:
  /// **'Entrar em Guilda'**
  String get joinGuild;

  /// No description provided for @createGuild.
  ///
  /// In pt, this message translates to:
  /// **'Criar Guilda'**
  String get createGuild;

  /// No description provided for @leaderboard.
  ///
  /// In pt, this message translates to:
  /// **'Ranking'**
  String get leaderboard;

  /// No description provided for @globalRanking.
  ///
  /// In pt, this message translates to:
  /// **'Ranking Global'**
  String get globalRanking;

  /// No description provided for @friendsRanking.
  ///
  /// In pt, this message translates to:
  /// **'Ranking de Amigos'**
  String get friendsRanking;

  /// No description provided for @guildRanking.
  ///
  /// In pt, this message translates to:
  /// **'Ranking da Guilda'**
  String get guildRanking;

  /// No description provided for @missions.
  ///
  /// In pt, this message translates to:
  /// **'Missões'**
  String get missions;

  /// No description provided for @weeklyMissions.
  ///
  /// In pt, this message translates to:
  /// **'Missões Semanais'**
  String get weeklyMissions;

  /// No description provided for @specialMissions.
  ///
  /// In pt, this message translates to:
  /// **'Missões Especiais'**
  String get specialMissions;

  /// No description provided for @completedMissions.
  ///
  /// In pt, this message translates to:
  /// **'Missões Completas'**
  String get completedMissions;

  /// No description provided for @missionProgress.
  ///
  /// In pt, this message translates to:
  /// **'Progresso da Missão'**
  String get missionProgress;

  /// No description provided for @missionReward.
  ///
  /// In pt, this message translates to:
  /// **'Recompensa da Missão'**
  String get missionReward;

  /// No description provided for @claimReward.
  ///
  /// In pt, this message translates to:
  /// **'Receber Recompensa'**
  String get claimReward;

  /// No description provided for @missionDescription.
  ///
  /// In pt, this message translates to:
  /// **'Descrição da Missão'**
  String get missionDescription;

  /// No description provided for @missionObjective.
  ///
  /// In pt, this message translates to:
  /// **'Objetivo da Missão'**
  String get missionObjective;

  /// No description provided for @myDailyMissions.
  ///
  /// In pt, this message translates to:
  /// **'Minhas Missões Diárias'**
  String get myDailyMissions;

  /// No description provided for @noMissionsSelectedMissions.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma missão diária selecionada.\nEscolha até'**
  String get noMissionsSelectedMissions;

  /// No description provided for @missionsBelow.
  ///
  /// In pt, this message translates to:
  /// **'missões abaixo!'**
  String get missionsBelow;

  /// No description provided for @saveChanges.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR ALTERAÇÕES'**
  String get saveChanges;

  /// No description provided for @availableMissions.
  ///
  /// In pt, this message translates to:
  /// **'Missões Disponíveis'**
  String get availableMissions;

  /// No description provided for @filterAttribute.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar Atributo'**
  String get filterAttribute;

  /// No description provided for @allAttributes.
  ///
  /// In pt, this message translates to:
  /// **'Todos Atributos'**
  String get allAttributes;

  /// No description provided for @noMissionsFound.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma missão encontrada para este filtro ou todas já foram selecionadas como diárias.'**
  String get noMissionsFound;

  /// No description provided for @missionsUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Suas missões diárias foram atualizadas!'**
  String get missionsUpdated;

  /// No description provided for @errorUpdatingMissions.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao atualizar suas missões diárias.'**
  String get errorUpdatingMissions;

  /// No description provided for @attention.
  ///
  /// In pt, this message translates to:
  /// **'Atenção'**
  String get attention;

  /// No description provided for @noChangesToSave.
  ///
  /// In pt, this message translates to:
  /// **'Não há alterações para serem salvas.'**
  String get noChangesToSave;

  /// No description provided for @conquests.
  ///
  /// In pt, this message translates to:
  /// **'Conquistas'**
  String get conquests;

  /// No description provided for @unlockedAchievements.
  ///
  /// In pt, this message translates to:
  /// **'Conquistas Desbloqueadas'**
  String get unlockedAchievements;

  /// No description provided for @lockedAchievements.
  ///
  /// In pt, this message translates to:
  /// **'Conquistas Bloqueadas'**
  String get lockedAchievements;

  /// No description provided for @achievementProgress.
  ///
  /// In pt, this message translates to:
  /// **'Progresso da Conquista'**
  String get achievementProgress;

  /// No description provided for @achievementReward.
  ///
  /// In pt, this message translates to:
  /// **'Recompensa da Conquista'**
  String get achievementReward;

  /// No description provided for @achievementDescription.
  ///
  /// In pt, this message translates to:
  /// **'Descrição da Conquista'**
  String get achievementDescription;

  /// No description provided for @rareAchievement.
  ///
  /// In pt, this message translates to:
  /// **'Conquista Rara'**
  String get rareAchievement;

  /// No description provided for @epicAchievement.
  ///
  /// In pt, this message translates to:
  /// **'Conquista Épica'**
  String get epicAchievement;

  /// No description provided for @legendaryAchievement.
  ///
  /// In pt, this message translates to:
  /// **'Conquista Lendária'**
  String get legendaryAchievement;

  /// No description provided for @ranking.
  ///
  /// In pt, this message translates to:
  /// **'Ranking'**
  String get ranking;

  /// No description provided for @position.
  ///
  /// In pt, this message translates to:
  /// **'Posição'**
  String get position;

  /// No description provided for @score.
  ///
  /// In pt, this message translates to:
  /// **'Pontuação'**
  String get score;

  /// No description provided for @globalLeaderboard.
  ///
  /// In pt, this message translates to:
  /// **'Ranking Global'**
  String get globalLeaderboard;

  /// No description provided for @weeklyLeaderboard.
  ///
  /// In pt, this message translates to:
  /// **'Ranking Semanal'**
  String get weeklyLeaderboard;

  /// No description provided for @monthlyLeaderboard.
  ///
  /// In pt, this message translates to:
  /// **'Ranking Mensal'**
  String get monthlyLeaderboard;

  /// No description provided for @allTimeLeaderboard.
  ///
  /// In pt, this message translates to:
  /// **'Ranking Geral'**
  String get allTimeLeaderboard;

  /// No description provided for @myRanking.
  ///
  /// In pt, this message translates to:
  /// **'Minha Classificação'**
  String get myRanking;

  /// No description provided for @players.
  ///
  /// In pt, this message translates to:
  /// **'Jogadores'**
  String get players;

  /// No description provided for @guilds.
  ///
  /// In pt, this message translates to:
  /// **'Guildas'**
  String get guilds;

  /// No description provided for @searchPlayerOrGuild.
  ///
  /// In pt, this message translates to:
  /// **'Buscar jogador ou guilda...'**
  String get searchPlayerOrGuild;

  /// No description provided for @searchGuildOrLeader.
  ///
  /// In pt, this message translates to:
  /// **'Buscar guilda ou líder...'**
  String get searchGuildOrLeader;

  /// No description provided for @sortBy.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar por:'**
  String get sortBy;

  /// No description provided for @region.
  ///
  /// In pt, this message translates to:
  /// **'Região:'**
  String get region;

  /// No description provided for @allRegions.
  ///
  /// In pt, this message translates to:
  /// **'Todas as Regiões'**
  String get allRegions;

  /// No description provided for @noPlayersFound.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum jogador encontrado.'**
  String get noPlayersFound;

  /// No description provided for @noGuildsFound.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma guilda encontrada.'**
  String get noGuildsFound;

  /// No description provided for @leader.
  ///
  /// In pt, this message translates to:
  /// **'Líder'**
  String get leader;

  /// No description provided for @totalAura.
  ///
  /// In pt, this message translates to:
  /// **'Aura Total'**
  String get totalAura;

  /// No description provided for @members.
  ///
  /// In pt, this message translates to:
  /// **'Membros'**
  String get members;

  /// No description provided for @aura.
  ///
  /// In pt, this message translates to:
  /// **'Aura'**
  String get aura;

  /// No description provided for @errorLoadingPlayerRanking.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar o ranking de jogadores.'**
  String get errorLoadingPlayerRanking;

  /// No description provided for @errorLoadingGuildRanking.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar o ranking de guildas.'**
  String get errorLoadingGuildRanking;

  /// No description provided for @myFriends.
  ///
  /// In pt, this message translates to:
  /// **'Meus Amigos'**
  String get myFriends;

  /// No description provided for @addFriend.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Amigo'**
  String get addFriend;

  /// No description provided for @removeFriend.
  ///
  /// In pt, this message translates to:
  /// **'Remover Amigo'**
  String get removeFriend;

  /// No description provided for @acceptFriend.
  ///
  /// In pt, this message translates to:
  /// **'Aceitar Amigo'**
  String get acceptFriend;

  /// No description provided for @rejectFriend.
  ///
  /// In pt, this message translates to:
  /// **'Rejeitar Amigo'**
  String get rejectFriend;

  /// No description provided for @blockUser.
  ///
  /// In pt, this message translates to:
  /// **'Bloquear Usuário'**
  String get blockUser;

  /// No description provided for @unblockUser.
  ///
  /// In pt, this message translates to:
  /// **'Desbloquear Usuário'**
  String get unblockUser;

  /// No description provided for @sendMessage.
  ///
  /// In pt, this message translates to:
  /// **'Enviar Mensagem'**
  String get sendMessage;

  /// No description provided for @viewProfile.
  ///
  /// In pt, this message translates to:
  /// **'Ver Perfil'**
  String get viewProfile;

  /// No description provided for @onlineNow.
  ///
  /// In pt, this message translates to:
  /// **'Online Agora'**
  String get onlineNow;

  /// No description provided for @lastSeen.
  ///
  /// In pt, this message translates to:
  /// **'Visto pela última vez'**
  String get lastSeen;

  /// No description provided for @friendshipLevel.
  ///
  /// In pt, this message translates to:
  /// **'Nível de Amizade'**
  String get friendshipLevel;

  /// No description provided for @itemRoulette.
  ///
  /// In pt, this message translates to:
  /// **'Roleta de Itens'**
  String get itemRoulette;

  /// No description provided for @spinRoulette.
  ///
  /// In pt, this message translates to:
  /// **'Girar Roleta'**
  String get spinRoulette;

  /// No description provided for @itemWon.
  ///
  /// In pt, this message translates to:
  /// **'Item Ganho'**
  String get itemWon;

  /// No description provided for @commonItem.
  ///
  /// In pt, this message translates to:
  /// **'Item Comum'**
  String get commonItem;

  /// No description provided for @rareItem.
  ///
  /// In pt, this message translates to:
  /// **'Item Raro'**
  String get rareItem;

  /// No description provided for @epicItem.
  ///
  /// In pt, this message translates to:
  /// **'Item Épico'**
  String get epicItem;

  /// No description provided for @legendaryItem.
  ///
  /// In pt, this message translates to:
  /// **'Item Lendário'**
  String get legendaryItem;

  /// No description provided for @mythicItem.
  ///
  /// In pt, this message translates to:
  /// **'Item Mítico'**
  String get mythicItem;

  /// No description provided for @equipment.
  ///
  /// In pt, this message translates to:
  /// **'Equipamento'**
  String get equipment;

  /// No description provided for @consumable.
  ///
  /// In pt, this message translates to:
  /// **'Consumível'**
  String get consumable;

  /// No description provided for @material.
  ///
  /// In pt, this message translates to:
  /// **'Material'**
  String get material;

  /// No description provided for @profileSetup.
  ///
  /// In pt, this message translates to:
  /// **'Configuração do Perfil'**
  String get profileSetup;

  /// No description provided for @completeProfile.
  ///
  /// In pt, this message translates to:
  /// **'Complete seu perfil'**
  String get completeProfile;

  /// No description provided for @profilePicture.
  ///
  /// In pt, this message translates to:
  /// **'Foto do Perfil'**
  String get profilePicture;

  /// No description provided for @selectImage.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar Imagem'**
  String get selectImage;

  /// No description provided for @basicInfo.
  ///
  /// In pt, this message translates to:
  /// **'Informações Básicas'**
  String get basicInfo;

  /// No description provided for @physicalStats.
  ///
  /// In pt, this message translates to:
  /// **'Estatísticas Físicas'**
  String get physicalStats;

  /// No description provided for @fitnessGoals.
  ///
  /// In pt, this message translates to:
  /// **'Objetivos de Fitness'**
  String get fitnessGoals;

  /// No description provided for @experienceLevel.
  ///
  /// In pt, this message translates to:
  /// **'Nível de Experiência'**
  String get experienceLevel;

  /// No description provided for @beginner.
  ///
  /// In pt, this message translates to:
  /// **'Iniciante'**
  String get beginner;

  /// No description provided for @intermediate.
  ///
  /// In pt, this message translates to:
  /// **'Intermediário'**
  String get intermediate;

  /// No description provided for @advanced.
  ///
  /// In pt, this message translates to:
  /// **'Avançado'**
  String get advanced;

  /// No description provided for @expert.
  ///
  /// In pt, this message translates to:
  /// **'Especialista'**
  String get expert;

  /// No description provided for @today.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In pt, this message translates to:
  /// **'Esta Semana'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In pt, this message translates to:
  /// **'Este Mês'**
  String get thisMonth;

  /// No description provided for @thisYear.
  ///
  /// In pt, this message translates to:
  /// **'Este Ano'**
  String get thisYear;

  /// No description provided for @minutes.
  ///
  /// In pt, this message translates to:
  /// **'minutos'**
  String get minutes;

  /// No description provided for @hours.
  ///
  /// In pt, this message translates to:
  /// **'horas'**
  String get hours;

  /// No description provided for @days.
  ///
  /// In pt, this message translates to:
  /// **'dias'**
  String get days;

  /// No description provided for @weeks.
  ///
  /// In pt, this message translates to:
  /// **'semanas'**
  String get weeks;

  /// No description provided for @months.
  ///
  /// In pt, this message translates to:
  /// **'meses'**
  String get months;

  /// No description provided for @years.
  ///
  /// In pt, this message translates to:
  /// **'anos'**
  String get years;

  /// No description provided for @share.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar'**
  String get share;

  /// No description provided for @like.
  ///
  /// In pt, this message translates to:
  /// **'Curtir'**
  String get like;

  /// No description provided for @comment.
  ///
  /// In pt, this message translates to:
  /// **'Comentar'**
  String get comment;

  /// No description provided for @follow.
  ///
  /// In pt, this message translates to:
  /// **'Seguir'**
  String get follow;

  /// No description provided for @unfollow.
  ///
  /// In pt, this message translates to:
  /// **'Deixar de Seguir'**
  String get unfollow;

  /// No description provided for @report.
  ///
  /// In pt, this message translates to:
  /// **'Denunciar'**
  String get report;

  /// No description provided for @refresh.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar'**
  String get refresh;

  /// No description provided for @retry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar Novamente'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get close;

  /// No description provided for @open.
  ///
  /// In pt, this message translates to:
  /// **'Abrir'**
  String get open;

  /// No description provided for @view.
  ///
  /// In pt, this message translates to:
  /// **'Visualizar'**
  String get view;

  /// No description provided for @hide.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar'**
  String get hide;

  /// No description provided for @show.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar'**
  String get show;

  /// No description provided for @navigationError.
  ///
  /// In pt, this message translates to:
  /// **'Erro de Navegação'**
  String get navigationError;

  /// No description provided for @guildProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil da Guilda'**
  String get guildProfile;

  /// No description provided for @guildMembers.
  ///
  /// In pt, this message translates to:
  /// **'Membros da Guilda'**
  String get guildMembers;

  /// No description provided for @guildMaster.
  ///
  /// In pt, this message translates to:
  /// **'Mestre da Guilda'**
  String get guildMaster;

  /// No description provided for @guildOfficers.
  ///
  /// In pt, this message translates to:
  /// **'Oficiais da Guilda'**
  String get guildOfficers;

  /// No description provided for @guildLevel.
  ///
  /// In pt, this message translates to:
  /// **'Nível da Guilda'**
  String get guildLevel;

  /// No description provided for @guildExp.
  ///
  /// In pt, this message translates to:
  /// **'EXP da Guilda'**
  String get guildExp;

  /// No description provided for @guildDescription.
  ///
  /// In pt, this message translates to:
  /// **'Descrição da Guilda'**
  String get guildDescription;

  /// No description provided for @leaveGuild.
  ///
  /// In pt, this message translates to:
  /// **'Sair da Guilda'**
  String get leaveGuild;

  /// No description provided for @inviteToGuild.
  ///
  /// In pt, this message translates to:
  /// **'Convidar para Guilda'**
  String get inviteToGuild;

  /// No description provided for @guildSettings.
  ///
  /// In pt, this message translates to:
  /// **'Configurações da Guilda'**
  String get guildSettings;

  /// No description provided for @guildChat.
  ///
  /// In pt, this message translates to:
  /// **'Chat da Guilda'**
  String get guildChat;

  /// No description provided for @unknownGuild.
  ///
  /// In pt, this message translates to:
  /// **'Guilda Desconhecida'**
  String get unknownGuild;

  /// No description provided for @unknownOwner.
  ///
  /// In pt, this message translates to:
  /// **'Dono Desconhecido'**
  String get unknownOwner;

  /// No description provided for @noDescription.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma descrição.'**
  String get noDescription;

  /// No description provided for @owner.
  ///
  /// In pt, this message translates to:
  /// **'Dono'**
  String get owner;

  /// No description provided for @treasurer.
  ///
  /// In pt, this message translates to:
  /// **'Tesoureiro'**
  String get treasurer;

  /// No description provided for @member.
  ///
  /// In pt, this message translates to:
  /// **'Membro'**
  String get member;

  /// No description provided for @someone.
  ///
  /// In pt, this message translates to:
  /// **'Alguém'**
  String get someone;

  /// No description provided for @unknown.
  ///
  /// In pt, this message translates to:
  /// **'Desconhecido'**
  String get unknown;

  /// No description provided for @cargo.
  ///
  /// In pt, this message translates to:
  /// **'cargo'**
  String get cargo;

  /// No description provided for @guildOwner.
  ///
  /// In pt, this message translates to:
  /// **'Líder'**
  String get guildOwner;

  /// No description provided for @official.
  ///
  /// In pt, this message translates to:
  /// **'Oficial'**
  String get official;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
