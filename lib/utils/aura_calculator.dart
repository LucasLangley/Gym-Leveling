// --- TÍTULOS E SUAS CONDIÇÕES ---
const Map<String, Map<String, dynamic>> availableTitles = {
  'Aspirante': {'condition': 'default', 'bonuses': {}, 'expReward': 0},
  'Iniciante da Força': {'condition': 'FOR >= 25', 'bonuses': {'FOR': 5}, 'expReward': 50},
  'Resistente': {'condition': 'VIT >= 25', 'bonuses': {'VIT': 7}, 'expReward': 50},
  'Veloz': {'condition': 'AGI >= 25', 'bonuses': {'AGI': 8}, 'expReward': 50},
  'Sábio': {'condition': 'INT >= 25', 'bonuses': {'INT': 6}, 'expReward': 50},
  'Observador': {'condition': 'PER >= 25', 'bonuses': {'PER': 10}, 'expReward': 50},
  'Guerreiro': {'condition': 'FOR >= 50', 'bonuses': {'FOR': 10, 'VIT': 5}, 'expReward': 100},
  'Tanque': {'condition': 'VIT >= 50', 'bonuses': {'VIT': 15, 'FOR': 3}, 'expReward': 100},
  'Assassino': {'condition': 'AGI >= 50', 'bonuses': {'AGI': 12, 'PER': 5}, 'expReward': 100},
  'Mago': {'condition': 'INT >= 50', 'bonuses': {'INT': 12, 'MP_MAX_BONUS': 20}, 'expReward': 100},
  'Explorador': {'condition': 'PER >= 50', 'bonuses': {'PER': 15, 'AGI': 3}, 'expReward': 100},
  'Lenda da Força': {'condition': 'FOR >= 100', 'bonuses': {'FOR': 20, 'VIT': 10}, 'expReward': 200},
  'Imortal': {'condition': 'VIT >= 100', 'bonuses': {'VIT': 25, 'HP_MAX_BONUS': 50}, 'expReward': 200},
  'Sombra': {'condition': 'AGI >= 100', 'bonuses': {'AGI': 20, 'PER': 8}, 'expReward': 200},
  'Arqui-Mago': {'condition': 'INT >= 100', 'bonuses': {'INT': 22, 'MP_MAX_BONUS': 40}, 'expReward': 200},
  'Onividente': {'condition': 'PER >= 100', 'bonuses': {'PER': 25, 'INT': 5}, 'expReward': 200},
};

// --- CLASSES E SUAS CONDIÇÕES ---
const Map<String, Map<String, dynamic>> availableClasses = {
  'Nenhuma': {'condition': 'default', 'bonuses': {}},
  // Classes Básicas (Nível 3)
  'Guerreiro': {'condition': 'level >= 3', 'baseBonuses': {'FOR': 8, 'VIT': 5}, 'scalingBonuses': {'FOR': 2, 'VIT': 1}},
  'Mago': {'condition': 'level >= 3', 'baseBonuses': {'INT': 8, 'MP_MAX_BONUS': 15}, 'scalingBonuses': {'INT': 2, 'MP_MAX_BONUS': 3}},
  'Arqueiro': {'condition': 'level >= 3', 'baseBonuses': {'AGI': 7, 'PER': 5}, 'scalingBonuses': {'AGI': 2, 'PER': 1}},
  // Classes Intermediárias (Nível 6)
  'Paladino': {'condition': 'level >= 6', 'baseBonuses': {'FOR': 6, 'VIT': 10}, 'scalingBonuses': {'FOR': 1, 'VIT': 2}},
  'Assassino': {'condition': 'level >= 6', 'baseBonuses': {'AGI': 12, 'PER': 3}, 'scalingBonuses': {'AGI': 3, 'PER': 1}},
  'Necromante': {'condition': 'level >= 6', 'baseBonuses': {'INT': 10, 'PER': 4}, 'scalingBonuses': {'INT': 2, 'PER': 1}},
  // Classes Avançadas (Nível 9)
  'Berserker': {'condition': 'level >= 9', 'baseBonuses': {'FOR': 15, 'AGI': 5}, 'scalingBonuses': {'FOR': 3, 'AGI': 1}},
  'Arcano': {'condition': 'level >= 9', 'baseBonuses': {'INT': 15, 'MP_MAX_BONUS': 25}, 'scalingBonuses': {'INT': 3, 'MP_MAX_BONUS': 4}},
  'Ranger': {'condition': 'level >= 9', 'baseBonuses': {'AGI': 8, 'PER': 8}, 'scalingBonuses': {'AGI': 2, 'PER': 2}},
  // Classes Legendárias (Nível 12)
  'Lorde da Guerra': {'condition': 'level >= 12', 'baseBonuses': {'FOR': 20, 'VIT': 15}, 'scalingBonuses': {'FOR': 4, 'VIT': 2}},
  'Mestre Arcano': {'condition': 'level >= 12', 'baseBonuses': {'INT': 20, 'MP_MAX_BONUS': 35}, 'scalingBonuses': {'INT': 4, 'MP_MAX_BONUS': 5}},
  'Sombra Letal': {'condition': 'level >= 12', 'baseBonuses': {'AGI': 18, 'PER': 12}, 'scalingBonuses': {'AGI': 3, 'PER': 2}},
};



// Função global para calcular aura - simplesmente a soma de todos os atributos finais
int calculateTotalAura({
  required Map<String, int> baseStats,
  required Map<String, int> bonusStats,
  required String currentTitle,
  required String currentJob,
  required int level,
  Map<String, bool>? completedAchievements,
}) {
  int totalAura = 0;
  
  // Somar apenas stats base + bônus (que já inclui tudo: itens, título, classe, conquistas)
  for (String stat in ['FOR', 'VIT', 'AGI', 'INT', 'PER']) {
    totalAura += (baseStats[stat] ?? 0) + (bonusStats[stat] ?? 0);
  }
  
  return totalAura;
} 