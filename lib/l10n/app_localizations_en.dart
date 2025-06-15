// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Gym Leveling';

  @override
  String get settings => 'SETTINGS';

  @override
  String get notifications =>
      'Notifications displayed in recent notifications:';

  @override
  String get globalNotifications => 'Global';

  @override
  String get guildNotifications => 'Guild';

  @override
  String get friendNotifications => 'Friends';

  @override
  String get restTimeDefault => 'Default rest time (seconds):';

  @override
  String get language => 'Language:';

  @override
  String get portuguese => 'Português';

  @override
  String get english => 'English';

  @override
  String get logout => 'LOGOUT';

  @override
  String get logoutConfirmation => 'Confirm Logout';

  @override
  String get logoutConfirmationMessage => 'Are you sure you want to logout?';

  @override
  String get logoutButton => 'Logout';

  @override
  String get cancel => 'Cancel';

  @override
  String get error => 'Error';

  @override
  String logoutError(Object error) {
    return 'Error logging out: $error';
  }

  @override
  String get ok => 'OK';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get loginButton => 'LOGIN';

  @override
  String get register => 'REGISTER';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get workouts => 'Workouts';

  @override
  String get social => 'Social';

  @override
  String get loading => 'Loading...';

  @override
  String get success => 'Success';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get finish => 'Finish';

  @override
  String get search => 'Search';

  @override
  String get level => 'Level';

  @override
  String get experience => 'Experience';

  @override
  String get points => 'Points';

  @override
  String get player => 'Player';

  @override
  String get none => 'None';

  @override
  String get title => 'Title';

  @override
  String get reward => 'Reward';

  @override
  String get gymLeveling => 'GYM LEVELING';

  @override
  String get playerEmail => 'Player Email';

  @override
  String get dungeonKey => 'Dungeon Key (Password)';

  @override
  String get rememberKey => 'Remember Dungeon Key';

  @override
  String get forgotKey => 'Forgot my key';

  @override
  String get enterDungeon => 'ENTER THE DUNGEON';

  @override
  String get noAccess => 'No access? ';

  @override
  String get becomePlayer => 'Become a Player';

  @override
  String get missingItems => 'MISSING ITEMS!';

  @override
  String get fillEmailPassword => 'Please fill in the email and Dungeon Key.';

  @override
  String get newMission => 'New Mission';

  @override
  String get secretMission =>
      'You received the Secret Mission \"Courage of the Weak\".';

  @override
  String get heartWarning =>
      'Your heart will stop in 0.02 seconds if you don\'t accept it.';

  @override
  String get acceptMission => 'Do you want to accept?';

  @override
  String get system => 'System';

  @override
  String get congratsPlayer => 'Congratulations, you became a Player!';

  @override
  String get systemWarning => 'System Warning';

  @override
  String get honestWarning =>
      'Be honest with the system, otherwise you will face severe consequences.';

  @override
  String get understood => 'Understood';

  @override
  String get gameOver => 'Game Over';

  @override
  String get youDied => 'You died.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get loginFailed => 'Login Failed';

  @override
  String get invalidCredentials => 'Invalid email or Dungeon Key.';

  @override
  String get invalidEmailFormat => 'Invalid email format.';

  @override
  String get loginError => 'An error occurred while trying to login.';

  @override
  String get recoverKey => 'Recover Key';

  @override
  String get forceOpenDungeon =>
      'Forcing dungeon opening, enter the Player\'s email for key recovery:';

  @override
  String get playerEmailLabel => 'Player Email';

  @override
  String get send => 'Send';

  @override
  String get keyDungeonSent => 'Dungeon Key sent to the informed email!';

  @override
  String get passwordResetError => 'Error sending recovery email.';

  @override
  String get noPlayerFound => 'No player found with this email.';

  @override
  String get failure => 'Failure';

  @override
  String get becomePlayerTitle => 'Become a Player';

  @override
  String get foundDoubleDungeon => 'YOU FOUND A DOUBLE DUNGEON!';

  @override
  String get createAccount => 'Create Account';

  @override
  String get name => 'Name';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmDungeonKey => 'Confirm Dungeon Key';

  @override
  String get forceOpen => 'FORCE OPEN';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get loginHere => 'Login here';

  @override
  String get fillAllFields => 'Please fill in all fields.';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get passwordMismatch => 'Passwords don\'t match.';

  @override
  String get registrationError => 'Error creating account';

  @override
  String get registrationFailed => 'Registration Failed';

  @override
  String get emailInUse => 'This email is already in use by another Player.';

  @override
  String get weakPassword => 'The Dungeon Key is too weak.';

  @override
  String get doubleDungeon => 'Double Dungeon!';

  @override
  String get doubleDungeonMessage =>
      'Player forced the opening of the Double Dungeon!\nPrepare for login.';

  @override
  String get toLogin => 'To Login!';

  @override
  String get criticalError => 'Critical Error';

  @override
  String get profileSetupError =>
      'There was a problem setting up your profile. Please try logging in or contact support if the problem persists.';

  @override
  String get welcomePlayer => 'Welcome, Player!';

  @override
  String get currentLevel => 'Current Level';

  @override
  String get totalExp => 'Total EXP';

  @override
  String get dailyMissions => 'Daily Missions';

  @override
  String get achievements => 'Achievements';

  @override
  String get statistics => 'Statistics';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get todaysWorkout => 'Today\'s Workout';

  @override
  String get friends => 'Friends';

  @override
  String get guild => 'Guild';

  @override
  String get shop => 'Shop';

  @override
  String get inventory => 'Inventory';

  @override
  String get auraTotal => 'TOTAL AURA';

  @override
  String get characterClass => 'CLASS';

  @override
  String get titleLabel => 'TITLE';

  @override
  String get hp => 'HP';

  @override
  String get mp => 'MP';

  @override
  String get exp => 'EXP';

  @override
  String get incredible => 'INCREDIBLE!';

  @override
  String get noMissionsSelected => 'No daily missions selected.';

  @override
  String get goToMissionsScreen =>
      'Go to the Missions screen (clipboard icon below) to choose your daily adventures!';

  @override
  String get rewardCollected => 'REWARD COLLECTED';

  @override
  String get collectRewards => 'COLLECT REWARDS';

  @override
  String get attentionPenalty =>
      'ATTENTION: Not completing Daily Missions and not collecting the reward will result in penalties!';

  @override
  String get viewFront => 'VIEW FRONT';

  @override
  String get viewBack => 'VIEW BACK';

  @override
  String get errorSavingMission => 'Error saving mission progress.';

  @override
  String get rewardsAlreadyCollected =>
      'You have already collected today\'s daily mission rewards.';

  @override
  String get completeAllMissions =>
      'You need to complete ALL selected daily missions to collect the reward.';

  @override
  String get needLoginRewards => 'You need to be logged in to collect rewards.';

  @override
  String get rewardRegistrationError =>
      'Could not register the reward. Please try again.';

  @override
  String get playerProfile => 'Player Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get profileStats => 'Profile Statistics';

  @override
  String get strength => 'Strength';

  @override
  String get endurance => 'Endurance';

  @override
  String get agility => 'Agility';

  @override
  String get intelligence => 'Intelligence';

  @override
  String get luck => 'Luck';

  @override
  String get height => 'Height';

  @override
  String get weight => 'Weight';

  @override
  String get age => 'Age';

  @override
  String get joinDate => 'Join Date';

  @override
  String get totalWorkouts => 'Total Workouts';

  @override
  String get favoriteExercise => 'Favorite Exercise';

  @override
  String get badges => 'Badges';

  @override
  String get personalRecords => 'Personal Records';

  @override
  String get change => 'Change';

  @override
  String get tapPhotoToChange => 'Tap photo to change';

  @override
  String get heightWeight => 'Height/Weight';

  @override
  String get biography => 'Biography';

  @override
  String get biographyTitle => 'BIOGRAPHY';

  @override
  String get availablePoints => 'Available Points';

  @override
  String get unsavedChanges => 'You have unsaved changes';

  @override
  String get saveAttributes => 'SAVE ATTRIBUTES';

  @override
  String get errorSavingAttributes =>
      'Error saving attributes. Please try again.';

  @override
  String get changeProfilePhoto => 'Change Profile Photo';

  @override
  String get chooseNewPhoto => 'Choose a new profile photo:';

  @override
  String get saving => 'Saving...';

  @override
  String get uploadingImage => 'Uploading image...';

  @override
  String get photoUpdatedSuccess => 'Profile photo updated successfully!';

  @override
  String get uploadError => 'Error uploading image. Please try again.';

  @override
  String get savePhotoError => 'Error saving photo';

  @override
  String get editBiography => 'Edit Biography';

  @override
  String get tellAboutYourself => 'Tell us about yourself:';

  @override
  String get writeBiographyHere => 'Write your biography here...';

  @override
  String get characters => 'characters';

  @override
  String get biographyTooLong => 'Biography too long. Maximum of';

  @override
  String get biographyUpdatedSuccess => 'Biography updated successfully!';

  @override
  String get errorSavingBiography => 'Error saving biography';

  @override
  String get editPhysicalInfo => 'Edit Physical Information';

  @override
  String get updatePhysicalInfo => 'Update your physical information:';

  @override
  String get heightM => 'Height (m)';

  @override
  String get weightKg => 'Weight (kg)';

  @override
  String get physicalInfoUpdatedSuccess =>
      'Physical information updated successfully!';

  @override
  String get errorSavingChanges => 'Error saving changes';

  @override
  String get head => 'Head';

  @override
  String get chest => 'Chest';

  @override
  String get rightHand => 'Right Hand';

  @override
  String get legs => 'Legs';

  @override
  String get feet => 'Feet';

  @override
  String get accessoryL => 'Accessory L.';

  @override
  String get ears => 'Ears';

  @override
  String get necklace => 'Necklace';

  @override
  String get leftHand => 'Left Hand';

  @override
  String get face => 'Face';

  @override
  String get bracelet => 'Bracelet';

  @override
  String get accessoryR => 'Accessory R.';

  @override
  String get rank => 'Rank';

  @override
  String get titleAspirante => 'Aspirant';

  @override
  String get titleInicianteForca => 'Strength Beginner';

  @override
  String get titleResistente => 'Resistant';

  @override
  String get titleVeloz => 'Swift';

  @override
  String get titleSabio => 'Wise';

  @override
  String get titleObservador => 'Observer';

  @override
  String get titleGuerreiro => 'Warrior';

  @override
  String get titleTanque => 'Tank';

  @override
  String get titleAssassino => 'Assassin';

  @override
  String get titleMago => 'Mage';

  @override
  String get titleExplorador => 'Explorer';

  @override
  String get titleLendaForca => 'Strength Legend';

  @override
  String get titleImortal => 'Immortal';

  @override
  String get titleSombra => 'Shadow';

  @override
  String get titleArquiMago => 'Arch-Mage';

  @override
  String get titleOnividente => 'Omniscient';

  @override
  String get classPaladino => 'Paladin';

  @override
  String get classNecromante => 'Necromancer';

  @override
  String get classBerserker => 'Berserker';

  @override
  String get classArcano => 'Arcane';

  @override
  String get classRanger => 'Ranger';

  @override
  String get classLordeGuerra => 'Warlord';

  @override
  String get classMestreArcano => 'Arcane Master';

  @override
  String get classSombraLetal => 'Lethal Shadow';

  @override
  String get itemElmoFerro => 'Iron Helm';

  @override
  String get itemCotaMalha => 'Reinforced Chain Mail';

  @override
  String get itemLaminaAgil => 'Agile Blade';

  @override
  String get itemBotasSombrias => 'Shadow Boots';

  @override
  String get itemColarMonarca => 'Monarch\'s Necklace';

  @override
  String get itemAnelPoder => 'Ring of Power';

  @override
  String get createNewGuild => 'CREATE NEW GUILD';

  @override
  String get errorLoadingInventory => 'Error loading inventory';

  @override
  String get errorSelectingImage => 'Error selecting image';

  @override
  String get heightBetween => 'Height must be between 1.00m and 2.50m';

  @override
  String get fillAllFieldsSelectPhoto =>
      'Please fill in all fields and select a photo';

  @override
  String get invalidHeight => 'Invalid height. Must be between 1.00m and 2.50m';

  @override
  String get errorSavingProfile => 'Error saving profile';

  @override
  String get noUserLoggedAchievements =>
      'No user logged in to load achievements.';

  @override
  String get achievementsLoadError => 'Error loading user achievement status';

  @override
  String get noAchievementsSystem => 'No achievements defined in the system.';

  @override
  String get workoutScreen => 'Workout Screen';

  @override
  String get startWorkout => 'Start Workout';

  @override
  String get endWorkout => 'End Workout';

  @override
  String get pauseWorkout => 'Pause Workout';

  @override
  String get resumeWorkout => 'Resume Workout';

  @override
  String get currentExercise => 'Current Exercise';

  @override
  String get sets => 'Sets';

  @override
  String get reps => 'Reps';

  @override
  String get restTime => 'Rest Time';

  @override
  String get nextExercise => 'Next Exercise';

  @override
  String get previousExercise => 'Previous Exercise';

  @override
  String get addSet => 'Add Set';

  @override
  String get removeSet => 'Remove Set';

  @override
  String get workoutCompleted => 'Workout Completed!';

  @override
  String get expGained => 'EXP Gained';

  @override
  String get timeElapsed => 'Time Elapsed';

  @override
  String get exercisesCompleted => 'Exercises Completed';

  @override
  String get socialHub => 'Social Hub';

  @override
  String get friendsList => 'Friends List';

  @override
  String get friendRequests => 'Friend Requests';

  @override
  String get findFriends => 'Find Friends';

  @override
  String get guildInfo => 'Guild Information';

  @override
  String get joinGuild => 'Join Guild';

  @override
  String get createGuild => 'Create Guild';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get globalRanking => 'Global Ranking';

  @override
  String get friendsRanking => 'Friends Ranking';

  @override
  String get guildRanking => 'Guild Ranking';

  @override
  String get missions => 'Missions';

  @override
  String get weeklyMissions => 'Weekly Missions';

  @override
  String get specialMissions => 'Special Missions';

  @override
  String get completedMissions => 'Completed Missions';

  @override
  String get missionProgress => 'Mission Progress';

  @override
  String get missionReward => 'Mission Reward';

  @override
  String get claimReward => 'Claim Reward';

  @override
  String get missionDescription => 'Mission Description';

  @override
  String get missionObjective => 'Mission Objective';

  @override
  String get myDailyMissions => 'My Daily Missions';

  @override
  String get noMissionsSelectedMissions =>
      'No daily missions selected.\nChoose up to';

  @override
  String get missionsBelow => 'missions below!';

  @override
  String get saveChanges => 'SAVE CHANGES';

  @override
  String get availableMissions => 'Available Missions';

  @override
  String get filterAttribute => 'Filter Attribute';

  @override
  String get allAttributes => 'All Attributes';

  @override
  String get noMissionsFound =>
      'No missions found for this filter or all have already been selected as daily.';

  @override
  String get missionsUpdated => 'Your daily missions have been updated!';

  @override
  String get errorUpdatingMissions => 'Error updating your daily missions.';

  @override
  String get attention => 'Attention';

  @override
  String get noChangesToSave => 'There are no changes to save.';

  @override
  String get conquests => 'Achievements';

  @override
  String get unlockedAchievements => 'Unlocked Achievements';

  @override
  String get lockedAchievements => 'Locked Achievements';

  @override
  String get achievementProgress => 'Achievement Progress';

  @override
  String get achievementReward => 'Achievement Reward';

  @override
  String get achievementDescription => 'Achievement Description';

  @override
  String get rareAchievement => 'Rare Achievement';

  @override
  String get epicAchievement => 'Epic Achievement';

  @override
  String get legendaryAchievement => 'Legendary Achievement';

  @override
  String get ranking => 'Ranking';

  @override
  String get position => 'Position';

  @override
  String get score => 'Score';

  @override
  String get globalLeaderboard => 'Global Leaderboard';

  @override
  String get weeklyLeaderboard => 'Weekly Leaderboard';

  @override
  String get monthlyLeaderboard => 'Monthly Leaderboard';

  @override
  String get allTimeLeaderboard => 'All Time Leaderboard';

  @override
  String get myRanking => 'My Ranking';

  @override
  String get players => 'Players';

  @override
  String get guilds => 'Guilds';

  @override
  String get searchPlayerOrGuild => 'Search player or guild...';

  @override
  String get searchGuildOrLeader => 'Search guild or leader...';

  @override
  String get sortBy => 'Sort by:';

  @override
  String get region => 'Region:';

  @override
  String get allRegions => 'All Regions';

  @override
  String get noPlayersFound => 'No players found.';

  @override
  String get noGuildsFound => 'No guilds found.';

  @override
  String get leader => 'Leader';

  @override
  String get totalAura => 'Total Aura';

  @override
  String get members => 'Members';

  @override
  String get aura => 'Aura';

  @override
  String get errorLoadingPlayerRanking => 'Error loading player rankings.';

  @override
  String get errorLoadingGuildRanking => 'Error loading guild rankings.';

  @override
  String get myFriends => 'My Friends';

  @override
  String get addFriend => 'Add Friend';

  @override
  String get removeFriend => 'Remove Friend';

  @override
  String get acceptFriend => 'Accept Friend';

  @override
  String get rejectFriend => 'Reject Friend';

  @override
  String get blockUser => 'Block User';

  @override
  String get unblockUser => 'Unblock User';

  @override
  String get sendMessage => 'Send Message';

  @override
  String get viewProfile => 'View Profile';

  @override
  String get onlineNow => 'Online Now';

  @override
  String get lastSeen => 'Last seen';

  @override
  String get friendshipLevel => 'Friendship Level';

  @override
  String get itemRoulette => 'Item Roulette';

  @override
  String get spinRoulette => 'Spin Roulette';

  @override
  String get itemWon => 'Item Won';

  @override
  String get commonItem => 'Common Item';

  @override
  String get rareItem => 'Rare Item';

  @override
  String get epicItem => 'Epic Item';

  @override
  String get legendaryItem => 'Legendary Item';

  @override
  String get mythicItem => 'Mythic Item';

  @override
  String get equipment => 'Equipment';

  @override
  String get consumable => 'Consumable';

  @override
  String get material => 'Material';

  @override
  String get profileSetup => 'Profile Setup';

  @override
  String get completeProfile => 'Complete your profile';

  @override
  String get profilePicture => 'Profile Picture';

  @override
  String get selectImage => 'Select Image';

  @override
  String get basicInfo => 'Basic Information';

  @override
  String get physicalStats => 'Physical Statistics';

  @override
  String get fitnessGoals => 'Fitness Goals';

  @override
  String get experienceLevel => 'Experience Level';

  @override
  String get beginner => 'Beginner';

  @override
  String get intermediate => 'Intermediate';

  @override
  String get advanced => 'Advanced';

  @override
  String get expert => 'Expert';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get thisYear => 'This Year';

  @override
  String get minutes => 'minutes';

  @override
  String get hours => 'hours';

  @override
  String get days => 'days';

  @override
  String get weeks => 'weeks';

  @override
  String get months => 'months';

  @override
  String get years => 'years';

  @override
  String get share => 'Share';

  @override
  String get like => 'Like';

  @override
  String get comment => 'Comment';

  @override
  String get follow => 'Follow';

  @override
  String get unfollow => 'Unfollow';

  @override
  String get report => 'Report';

  @override
  String get refresh => 'Refresh';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get open => 'Open';

  @override
  String get view => 'View';

  @override
  String get hide => 'Hide';

  @override
  String get show => 'Show';

  @override
  String get navigationError => 'Navigation Error';

  @override
  String get guildProfile => 'Guild Profile';

  @override
  String get guildMembers => 'Guild Members';

  @override
  String get guildMaster => 'Guild Master';

  @override
  String get guildOfficers => 'Guild Officers';

  @override
  String get guildLevel => 'Guild Level';

  @override
  String get guildExp => 'Guild EXP';

  @override
  String get guildDescription => 'Guild Description';

  @override
  String get leaveGuild => 'Leave Guild';

  @override
  String get inviteToGuild => 'Invite to Guild';

  @override
  String get guildSettings => 'Guild Settings';

  @override
  String get guildChat => 'Guild Chat';

  @override
  String get unknownGuild => 'Unknown Guild';

  @override
  String get unknownOwner => 'Unknown Owner';

  @override
  String get noDescription => 'No description.';

  @override
  String get owner => 'Owner';

  @override
  String get treasurer => 'Treasurer';

  @override
  String get member => 'Member';

  @override
  String get someone => 'Someone';

  @override
  String get unknown => 'Unknown';

  @override
  String get cargo => 'role';

  @override
  String get guildOwner => 'Leader';

  @override
  String get official => 'Officer';
}
