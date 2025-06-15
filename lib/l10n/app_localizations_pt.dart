// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Gym Leveling';

  @override
  String get settings => 'CONFIGURAÇÕES';

  @override
  String get notifications => 'Notificações exibidas em notificações recentes:';

  @override
  String get globalNotifications => 'Global';

  @override
  String get guildNotifications => 'Guilda';

  @override
  String get friendNotifications => 'Amigos';

  @override
  String get restTimeDefault => 'Tempo de descanso padrão (segundos):';

  @override
  String get language => 'Idioma:';

  @override
  String get portuguese => 'Português';

  @override
  String get english => 'English';

  @override
  String get logout => 'SAIR DA CONTA';

  @override
  String get logoutConfirmation => 'Confirmar Logout';

  @override
  String get logoutConfirmationMessage =>
      'Tem certeza que deseja sair da sua conta?';

  @override
  String get logoutButton => 'Sair';

  @override
  String get cancel => 'Cancelar';

  @override
  String get error => 'Erro';

  @override
  String logoutError(Object error) {
    return 'Erro ao fazer logout: $error';
  }

  @override
  String get ok => 'OK';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Senha';

  @override
  String get loginButton => 'ENTRAR';

  @override
  String get register => 'CADASTRAR';

  @override
  String get forgotPassword => 'Esqueceu a senha?';

  @override
  String get home => 'Início';

  @override
  String get profile => 'Perfil';

  @override
  String get workouts => 'Treinos';

  @override
  String get social => 'Social';

  @override
  String get loading => 'Carregando...';

  @override
  String get success => 'Sucesso';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get save => 'Salvar';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Deletar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get back => 'Voltar';

  @override
  String get next => 'Próximo';

  @override
  String get finish => 'Finalizar';

  @override
  String get search => 'Pesquisar';

  @override
  String get level => 'Nível';

  @override
  String get experience => 'Experiência';

  @override
  String get points => 'Pontos';

  @override
  String get player => 'Jogador';

  @override
  String get none => 'Nenhuma';

  @override
  String get title => 'Título';

  @override
  String get reward => 'Recompensa';

  @override
  String get gymLeveling => 'GYM LEVELING';

  @override
  String get playerEmail => 'E-mail do Jogador';

  @override
  String get dungeonKey => 'Chave da Dungeon (Senha)';

  @override
  String get rememberKey => 'Guardar chave da Dungeon';

  @override
  String get forgotKey => 'Esqueci minha chave';

  @override
  String get enterDungeon => 'ENTRAR NA DUNGEON';

  @override
  String get noAccess => 'Não tem acesso? ';

  @override
  String get becomePlayer => 'Se tornar um Jogador';

  @override
  String get missingItems => 'ITENS FALTANDO!';

  @override
  String get fillEmailPassword =>
      'Por favor, preencha o e-mail e a Chave da Dungeon.';

  @override
  String get newMission => 'Nova Missão';

  @override
  String get secretMission =>
      'Você recebeu a Missão Secreta \"Coragem do Fraco\".';

  @override
  String get heartWarning =>
      'Seu coração irá parar em 0.02 segundos se você não ceitá-la.';

  @override
  String get acceptMission => 'Deseja aceitar?';

  @override
  String get system => 'Sistema';

  @override
  String get congratsPlayer => 'Parabéns, você se tornou um Jogador!';

  @override
  String get systemWarning => 'Aviso do Sistema';

  @override
  String get honestWarning =>
      'Seja honesto com o sistema, caso contrário, enfrentará consequências severas.';

  @override
  String get understood => 'Entendido';

  @override
  String get gameOver => 'Fim de Jogo';

  @override
  String get youDied => 'Você morreu.';

  @override
  String get tryAgain => 'Tentar Novamente';

  @override
  String get loginFailed => 'Falha no Login';

  @override
  String get invalidCredentials => 'E-mail ou Chave da Dungeon inválidos.';

  @override
  String get invalidEmailFormat => 'O formato do e-mail é inválido.';

  @override
  String get loginError => 'Ocorreu um erro ao tentar fazer login.';

  @override
  String get recoverKey => 'Recuperar Chave';

  @override
  String get forceOpenDungeon =>
      'Forçando a abertura da dungeon, insira o e-mail do Jogador para recuperação da chave:';

  @override
  String get playerEmailLabel => 'E-mail do Jogador';

  @override
  String get send => 'Enviar';

  @override
  String get keyDungeonSent =>
      'Chave da Dungeon enviada para o e-mail informado!';

  @override
  String get passwordResetError => 'Erro ao enviar e-mail de recuperação.';

  @override
  String get noPlayerFound => 'Nenhum jogador encontrado com este e-mail.';

  @override
  String get failure => 'Falha';

  @override
  String get becomePlayerTitle => 'Se Tornar um Jogador';

  @override
  String get foundDoubleDungeon => 'VOCÊ ENCONTROU UMA DUNGEON DUPLA!';

  @override
  String get createAccount => 'Criar Conta';

  @override
  String get name => 'Nome';

  @override
  String get confirmPassword => 'Confirmar Senha';

  @override
  String get confirmDungeonKey => 'Confirmar Chave da Dungeon';

  @override
  String get forceOpen => 'FORÇAR ABERTURA';

  @override
  String get alreadyHaveAccount => 'Já tem uma conta? ';

  @override
  String get loginHere => 'Faça login aqui';

  @override
  String get fillAllFields => 'Por favor, preencha todos os campos.';

  @override
  String get pleaseEnterEmail => 'Por favor, insira seu e-mail';

  @override
  String get enterValidEmail => 'Insira um e-mail válido';

  @override
  String get passwordMinLength => 'A senha deve ter pelo menos 6 caracteres';

  @override
  String get pleaseConfirmPassword => 'Por favor, confirme sua senha';

  @override
  String get passwordMismatch => 'As senhas não coincidem.';

  @override
  String get registrationError => 'Erro ao criar conta';

  @override
  String get registrationFailed => 'Falha no Registro';

  @override
  String get emailInUse => 'Este e-mail já está em uso por outro Jogador.';

  @override
  String get weakPassword => 'A Chave da Dungeon é muito fraca.';

  @override
  String get doubleDungeon => 'Dungeon Dupla!';

  @override
  String get doubleDungeonMessage =>
      'Jogador forçou a abertura da Dungeon Dupla!\nPrepare-se para o login.';

  @override
  String get toLogin => 'Para o Login!';

  @override
  String get criticalError => 'Erro Crítico';

  @override
  String get profileSetupError =>
      'Houve um problema ao configurar seu perfil. Por favor, tente fazer login ou contate o suporte se o problema persistir.';

  @override
  String get welcomePlayer => 'Bem-vindo, Jogador!';

  @override
  String get currentLevel => 'Nível Atual';

  @override
  String get totalExp => 'EXP Total';

  @override
  String get dailyMissions => 'Missões Diárias';

  @override
  String get achievements => 'Conquistas';

  @override
  String get statistics => 'Estatísticas';

  @override
  String get recentActivity => 'Atividade Recente';

  @override
  String get todaysWorkout => 'Treino de Hoje';

  @override
  String get friends => 'Amigos';

  @override
  String get guild => 'Guilda';

  @override
  String get shop => 'Loja';

  @override
  String get inventory => 'Inventário';

  @override
  String get auraTotal => 'AURA TOTAL';

  @override
  String get characterClass => 'CLASSE';

  @override
  String get titleLabel => 'TÍTULO';

  @override
  String get hp => 'HP';

  @override
  String get mp => 'MP';

  @override
  String get exp => 'EXP';

  @override
  String get incredible => 'INCRÍVEL!';

  @override
  String get noMissionsSelected => 'Nenhuma missão diária selecionada.';

  @override
  String get goToMissionsScreen =>
      'Vá para a tela de Missões (ícone de prancheta abaixo) para escolher suas aventuras diárias!';

  @override
  String get rewardCollected => 'RECOMPENSA COLETADA';

  @override
  String get collectRewards => 'COLETAR RECOMPENSAS';

  @override
  String get attentionPenalty =>
      'ATENÇÃO: Não completar as Missões Diárias e não coletar a recompensa resultará em penalidades!';

  @override
  String get viewFront => 'VER FRENTE';

  @override
  String get viewBack => 'VER COSTAS';

  @override
  String get errorSavingMission => 'Erro ao salvar progresso da missão.';

  @override
  String get rewardsAlreadyCollected =>
      'Você já coletou as recompensas da missão diária de hoje.';

  @override
  String get completeAllMissions =>
      'Você precisa completar TODAS as missões diárias selecionadas para coletar a recompensa.';

  @override
  String get needLoginRewards =>
      'Você precisa estar logado para coletar recompensas.';

  @override
  String get rewardRegistrationError =>
      'Não foi possível registrar a recompensa. Tente novamente.';

  @override
  String get playerProfile => 'Perfil do Jogador';

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String get profileStats => 'Estatísticas do Perfil';

  @override
  String get strength => 'Força';

  @override
  String get endurance => 'Resistência';

  @override
  String get agility => 'Agilidade';

  @override
  String get intelligence => 'Inteligência';

  @override
  String get luck => 'Sorte';

  @override
  String get height => 'Altura';

  @override
  String get weight => 'Peso';

  @override
  String get age => 'Idade';

  @override
  String get joinDate => 'Data de Ingresso';

  @override
  String get totalWorkouts => 'Total de Treinos';

  @override
  String get favoriteExercise => 'Exercício Favorito';

  @override
  String get badges => 'Medalhas';

  @override
  String get personalRecords => 'Recordes Pessoais';

  @override
  String get change => 'Alterar';

  @override
  String get tapPhotoToChange => 'Toque na foto para alterar';

  @override
  String get heightWeight => 'Altura/Peso';

  @override
  String get biography => 'Biografia';

  @override
  String get biographyTitle => 'BIOGRAFIA';

  @override
  String get availablePoints => 'Pontos Disponíveis';

  @override
  String get unsavedChanges => 'Você tem alterações não salvas';

  @override
  String get saveAttributes => 'SALVAR ATRIBUTOS';

  @override
  String get errorSavingAttributes =>
      'Erro ao salvar atributos. Tente novamente.';

  @override
  String get changeProfilePhoto => 'Alterar Foto de Perfil';

  @override
  String get chooseNewPhoto => 'Escolha uma nova foto de perfil:';

  @override
  String get saving => 'Salvando...';

  @override
  String get uploadingImage => 'Fazendo upload da imagem...';

  @override
  String get photoUpdatedSuccess => 'Foto de perfil atualizada com sucesso!';

  @override
  String get uploadError => 'Erro ao fazer upload da imagem. Tente novamente.';

  @override
  String get savePhotoError => 'Erro ao salvar foto';

  @override
  String get editBiography => 'Editar Biografia';

  @override
  String get tellAboutYourself => 'Conte um pouco sobre você:';

  @override
  String get writeBiographyHere => 'Escreva sua biografia aqui...';

  @override
  String get characters => 'caracteres';

  @override
  String get biographyTooLong => 'Biografia muito longa. Máximo de';

  @override
  String get biographyUpdatedSuccess => 'Biografia atualizada com sucesso!';

  @override
  String get errorSavingBiography => 'Erro ao salvar biografia';

  @override
  String get editPhysicalInfo => 'Editar Informações Físicas';

  @override
  String get updatePhysicalInfo => 'Atualize suas informações físicas:';

  @override
  String get heightM => 'Altura (m)';

  @override
  String get weightKg => 'Peso (kg)';

  @override
  String get physicalInfoUpdatedSuccess =>
      'Informações físicas atualizadas com sucesso!';

  @override
  String get errorSavingChanges => 'Erro ao salvar alterações';

  @override
  String get head => 'Cabeça';

  @override
  String get chest => 'Peitoral';

  @override
  String get rightHand => 'Mão Direita';

  @override
  String get legs => 'Pernas';

  @override
  String get feet => 'Pés';

  @override
  String get accessoryL => 'Acessório E.';

  @override
  String get ears => 'Orelhas';

  @override
  String get necklace => 'Colar';

  @override
  String get leftHand => 'Mão Esquerda';

  @override
  String get face => 'Rosto';

  @override
  String get bracelet => 'Bracelete';

  @override
  String get accessoryR => 'Acessório D.';

  @override
  String get rank => 'Rank';

  @override
  String get titleAspirante => 'Aspirante';

  @override
  String get titleInicianteForca => 'Iniciante da Força';

  @override
  String get titleResistente => 'Resistente';

  @override
  String get titleVeloz => 'Veloz';

  @override
  String get titleSabio => 'Sábio';

  @override
  String get titleObservador => 'Observador';

  @override
  String get titleGuerreiro => 'Guerreiro';

  @override
  String get titleTanque => 'Tanque';

  @override
  String get titleAssassino => 'Assassino';

  @override
  String get titleMago => 'Mago';

  @override
  String get titleExplorador => 'Explorador';

  @override
  String get titleLendaForca => 'Lenda da Força';

  @override
  String get titleImortal => 'Imortal';

  @override
  String get titleSombra => 'Sombra';

  @override
  String get titleArquiMago => 'Arqui-Mago';

  @override
  String get titleOnividente => 'Onividente';

  @override
  String get classPaladino => 'Paladino';

  @override
  String get classNecromante => 'Necromante';

  @override
  String get classBerserker => 'Berserker';

  @override
  String get classArcano => 'Arcano';

  @override
  String get classRanger => 'Ranger';

  @override
  String get classLordeGuerra => 'Lorde da Guerra';

  @override
  String get classMestreArcano => 'Mestre Arcano';

  @override
  String get classSombraLetal => 'Sombra Letal';

  @override
  String get itemElmoFerro => 'Elmo de Ferro';

  @override
  String get itemCotaMalha => 'Cota de Malha Reforçada';

  @override
  String get itemLaminaAgil => 'Lâmina Ágil';

  @override
  String get itemBotasSombrias => 'Botas Sombrias';

  @override
  String get itemColarMonarca => 'Colar do Monarca';

  @override
  String get itemAnelPoder => 'Anel de Poder';

  @override
  String get createNewGuild => 'CRIAR NOVA GUILDA';

  @override
  String get errorLoadingInventory => 'Erro ao carregar inventário';

  @override
  String get errorSelectingImage => 'Erro ao selecionar imagem';

  @override
  String get heightBetween => 'Altura deve estar entre 1.00m e 2.50m';

  @override
  String get fillAllFieldsSelectPhoto =>
      'Por favor, preencha todos os campos e selecione uma foto';

  @override
  String get invalidHeight => 'Altura inválida. Deve estar entre 1.00m e 2.50m';

  @override
  String get errorSavingProfile => 'Erro ao salvar perfil';

  @override
  String get noUserLoggedAchievements =>
      'Nenhum usuário logado para carregar conquistas.';

  @override
  String get achievementsLoadError =>
      'Erro ao carregar status das conquistas do usuário';

  @override
  String get noAchievementsSystem => 'Nenhuma conquista definida no sistema.';

  @override
  String get workoutScreen => 'Tela de Treino';

  @override
  String get startWorkout => 'Iniciar Treino';

  @override
  String get endWorkout => 'Finalizar Treino';

  @override
  String get pauseWorkout => 'Pausar Treino';

  @override
  String get resumeWorkout => 'Retomar Treino';

  @override
  String get currentExercise => 'Exercício Atual';

  @override
  String get sets => 'Séries';

  @override
  String get reps => 'Repetições';

  @override
  String get restTime => 'Tempo de Descanso';

  @override
  String get nextExercise => 'Próximo Exercício';

  @override
  String get previousExercise => 'Exercício Anterior';

  @override
  String get addSet => 'Adicionar Série';

  @override
  String get removeSet => 'Remover Série';

  @override
  String get workoutCompleted => 'Treino Concluído!';

  @override
  String get expGained => 'EXP Ganho';

  @override
  String get timeElapsed => 'Tempo Decorrido';

  @override
  String get exercisesCompleted => 'Exercícios Completos';

  @override
  String get socialHub => 'Central Social';

  @override
  String get friendsList => 'Lista de Amigos';

  @override
  String get friendRequests => 'Solicitações de Amizade';

  @override
  String get findFriends => 'Encontrar Amigos';

  @override
  String get guildInfo => 'Informações da Guilda';

  @override
  String get joinGuild => 'Entrar em Guilda';

  @override
  String get createGuild => 'Criar Guilda';

  @override
  String get leaderboard => 'Ranking';

  @override
  String get globalRanking => 'Ranking Global';

  @override
  String get friendsRanking => 'Ranking de Amigos';

  @override
  String get guildRanking => 'Ranking da Guilda';

  @override
  String get missions => 'Missões';

  @override
  String get weeklyMissions => 'Missões Semanais';

  @override
  String get specialMissions => 'Missões Especiais';

  @override
  String get completedMissions => 'Missões Completas';

  @override
  String get missionProgress => 'Progresso da Missão';

  @override
  String get missionReward => 'Recompensa da Missão';

  @override
  String get claimReward => 'Receber Recompensa';

  @override
  String get missionDescription => 'Descrição da Missão';

  @override
  String get missionObjective => 'Objetivo da Missão';

  @override
  String get myDailyMissions => 'Minhas Missões Diárias';

  @override
  String get noMissionsSelectedMissions =>
      'Nenhuma missão diária selecionada.\nEscolha até';

  @override
  String get missionsBelow => 'missões abaixo!';

  @override
  String get saveChanges => 'SALVAR ALTERAÇÕES';

  @override
  String get availableMissions => 'Missões Disponíveis';

  @override
  String get filterAttribute => 'Filtrar Atributo';

  @override
  String get allAttributes => 'Todos Atributos';

  @override
  String get noMissionsFound =>
      'Nenhuma missão encontrada para este filtro ou todas já foram selecionadas como diárias.';

  @override
  String get missionsUpdated => 'Suas missões diárias foram atualizadas!';

  @override
  String get errorUpdatingMissions => 'Erro ao atualizar suas missões diárias.';

  @override
  String get attention => 'Atenção';

  @override
  String get noChangesToSave => 'Não há alterações para serem salvas.';

  @override
  String get conquests => 'Conquistas';

  @override
  String get unlockedAchievements => 'Conquistas Desbloqueadas';

  @override
  String get lockedAchievements => 'Conquistas Bloqueadas';

  @override
  String get achievementProgress => 'Progresso da Conquista';

  @override
  String get achievementReward => 'Recompensa da Conquista';

  @override
  String get achievementDescription => 'Descrição da Conquista';

  @override
  String get rareAchievement => 'Conquista Rara';

  @override
  String get epicAchievement => 'Conquista Épica';

  @override
  String get legendaryAchievement => 'Conquista Lendária';

  @override
  String get ranking => 'Ranking';

  @override
  String get position => 'Posição';

  @override
  String get score => 'Pontuação';

  @override
  String get globalLeaderboard => 'Ranking Global';

  @override
  String get weeklyLeaderboard => 'Ranking Semanal';

  @override
  String get monthlyLeaderboard => 'Ranking Mensal';

  @override
  String get allTimeLeaderboard => 'Ranking Geral';

  @override
  String get myRanking => 'Minha Classificação';

  @override
  String get players => 'Jogadores';

  @override
  String get guilds => 'Guildas';

  @override
  String get searchPlayerOrGuild => 'Buscar jogador ou guilda...';

  @override
  String get searchGuildOrLeader => 'Buscar guilda ou líder...';

  @override
  String get sortBy => 'Ordenar por:';

  @override
  String get region => 'Região:';

  @override
  String get allRegions => 'Todas as Regiões';

  @override
  String get noPlayersFound => 'Nenhum jogador encontrado.';

  @override
  String get noGuildsFound => 'Nenhuma guilda encontrada.';

  @override
  String get leader => 'Líder';

  @override
  String get totalAura => 'Aura Total';

  @override
  String get members => 'Membros';

  @override
  String get aura => 'Aura';

  @override
  String get errorLoadingPlayerRanking =>
      'Erro ao carregar o ranking de jogadores.';

  @override
  String get errorLoadingGuildRanking =>
      'Erro ao carregar o ranking de guildas.';

  @override
  String get myFriends => 'Meus Amigos';

  @override
  String get addFriend => 'Adicionar Amigo';

  @override
  String get removeFriend => 'Remover Amigo';

  @override
  String get acceptFriend => 'Aceitar Amigo';

  @override
  String get rejectFriend => 'Rejeitar Amigo';

  @override
  String get blockUser => 'Bloquear Usuário';

  @override
  String get unblockUser => 'Desbloquear Usuário';

  @override
  String get sendMessage => 'Enviar Mensagem';

  @override
  String get viewProfile => 'Ver Perfil';

  @override
  String get onlineNow => 'Online Agora';

  @override
  String get lastSeen => 'Visto pela última vez';

  @override
  String get friendshipLevel => 'Nível de Amizade';

  @override
  String get itemRoulette => 'Roleta de Itens';

  @override
  String get spinRoulette => 'Girar Roleta';

  @override
  String get itemWon => 'Item Ganho';

  @override
  String get commonItem => 'Item Comum';

  @override
  String get rareItem => 'Item Raro';

  @override
  String get epicItem => 'Item Épico';

  @override
  String get legendaryItem => 'Item Lendário';

  @override
  String get mythicItem => 'Item Mítico';

  @override
  String get equipment => 'Equipamento';

  @override
  String get consumable => 'Consumível';

  @override
  String get material => 'Material';

  @override
  String get profileSetup => 'Configuração do Perfil';

  @override
  String get completeProfile => 'Complete seu perfil';

  @override
  String get profilePicture => 'Foto do Perfil';

  @override
  String get selectImage => 'Selecionar Imagem';

  @override
  String get basicInfo => 'Informações Básicas';

  @override
  String get physicalStats => 'Estatísticas Físicas';

  @override
  String get fitnessGoals => 'Objetivos de Fitness';

  @override
  String get experienceLevel => 'Nível de Experiência';

  @override
  String get beginner => 'Iniciante';

  @override
  String get intermediate => 'Intermediário';

  @override
  String get advanced => 'Avançado';

  @override
  String get expert => 'Especialista';

  @override
  String get today => 'Hoje';

  @override
  String get yesterday => 'Ontem';

  @override
  String get thisWeek => 'Esta Semana';

  @override
  String get thisMonth => 'Este Mês';

  @override
  String get thisYear => 'Este Ano';

  @override
  String get minutes => 'minutos';

  @override
  String get hours => 'horas';

  @override
  String get days => 'dias';

  @override
  String get weeks => 'semanas';

  @override
  String get months => 'meses';

  @override
  String get years => 'anos';

  @override
  String get share => 'Compartilhar';

  @override
  String get like => 'Curtir';

  @override
  String get comment => 'Comentar';

  @override
  String get follow => 'Seguir';

  @override
  String get unfollow => 'Deixar de Seguir';

  @override
  String get report => 'Denunciar';

  @override
  String get refresh => 'Atualizar';

  @override
  String get retry => 'Tentar Novamente';

  @override
  String get close => 'Fechar';

  @override
  String get open => 'Abrir';

  @override
  String get view => 'Visualizar';

  @override
  String get hide => 'Ocultar';

  @override
  String get show => 'Mostrar';

  @override
  String get navigationError => 'Erro de Navegação';

  @override
  String get guildProfile => 'Perfil da Guilda';

  @override
  String get guildMembers => 'Membros da Guilda';

  @override
  String get guildMaster => 'Mestre da Guilda';

  @override
  String get guildOfficers => 'Oficiais da Guilda';

  @override
  String get guildLevel => 'Nível da Guilda';

  @override
  String get guildExp => 'EXP da Guilda';

  @override
  String get guildDescription => 'Descrição da Guilda';

  @override
  String get leaveGuild => 'Sair da Guilda';

  @override
  String get inviteToGuild => 'Convidar para Guilda';

  @override
  String get guildSettings => 'Configurações da Guilda';

  @override
  String get guildChat => 'Chat da Guilda';

  @override
  String get unknownGuild => 'Guilda Desconhecida';

  @override
  String get unknownOwner => 'Dono Desconhecido';

  @override
  String get noDescription => 'Nenhuma descrição.';

  @override
  String get owner => 'Dono';

  @override
  String get treasurer => 'Tesoureiro';

  @override
  String get member => 'Membro';

  @override
  String get someone => 'Alguém';

  @override
  String get unknown => 'Desconhecido';

  @override
  String get cargo => 'cargo';

  @override
  String get guildOwner => 'Líder';

  @override
  String get official => 'Oficial';
}
