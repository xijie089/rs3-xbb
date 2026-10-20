--[[
XBB / Canonical compact names
Maps effect config names to struct IDs, compact labels, and original text.
Optional aliases match effect headings before a colon or line break.
Catalog derives its secondary lookups from these entries; display shortening
does not change saved effect identities or original hover text.
]]

return {
    COMBATV2_ABILITY_WEAPON_SOULFIRE_DOT_HIT = {
        id = 50069, name = "Soulfire bleed",
        text = "Soulfire - Damage over time",
    },
    COMBATV2_ACHTO_EFFECT = {
        id = 35809, name = "Achto CD",
        text = "Your Mazcab defensive reset effect will not activate for at least 60 seconds.",
    },
    COMBATV2_ADRENALINE_POTION_DUMMY_ABILITY = {
        id = 11599, name = "Adrenaline potion CD",
        aliases = { "adrenaline potion cooldown" },
        text = "Adrenaline potion prevention",
    },
    COMBATV2_ADRENALINE_URN = {
        id = 680, name = "Adrenaline urn",
        text = "Adrenaline urn - prevents your adrenaline draining while out of combat.",
    },
    COMBATV2_AFTERSHOCK_TRACKER = {
        id = 35804, name = "Aftershock",
        aliases = { "aftershock" },
        text = "After reaching 100%, create an explosion centered on your current target, dealing up to 40% per rank weapon damage to nearby enemies.",
    },
    COMBATV2_AGILITY_POTION_EFFECT = {
        id = 50246, name = "Agility potion",
        text = "Agility Potion Active - increases your Agility level temporarily.",
    },
    COMBATV2_ANTI_HEAL_DEBUFF = {
        id = 47203, name = "Spirit trauma",
        text = "Spirit trauma - Healing effects have been reduced by 40%.",
    },
    COMBATV2_ARCH_CONSUMABLE_EXCAVATION_XP_DUMMY_ABILITY = {
        id = 35951, name = "Archaeologist's tea",
        text = "Archaeologist's tea - Increases your XP by 50% while excavating.",
    },
    COMBATV2_ARCH_CONSUMABLE_MATERIAL_CHANCE_DUMMY_ABILITY = {
        id = 35946, name = "Material manual",
        text = "Material manual - Increases your chance of finding materials by 10% while excavating.",
    },
    COMBATV2_ARCH_CONSUMABLE_MATTOCK_PRECISION_DUMMY_ABILITY = {
        id = 35947, name = "Hi-spec monocle",
        text = "Hi-spec monocle - Increases your base mattock precision by 20% while excavating.",
    },
    COMBATV2_ARCH_CONSUMABLE_SOIL_CHANCE_DUMMY_ABILITY = {
        id = 35950, name = "Tarpaulin sheet",
        text = "Tarpaulin sheet - Increases your chance of finding soil by 10% while excavating.",
    },
    COMBATV2_ARCH_KHARIDET_PYLON_EFFECT_DUMMY_ABILITY = {
        id = 35940, name = "Protection of Zaros",
        text = "Protection of Zaros - An additional 10% Archaeology XP; a 5% increase to your mattock's precision (artefact discovery) and access to the Shadow Realm.",
    },
    COMBATV2_ARCH_ORTHEN_REX_EFFECT_DUMMY_ABILITY = {
        id = 44876, name = "Roar of Osseous",
        text = "Roar of Osseous - Anachronia activities grant an additional 25% experience and have enhanced drop rates.",
    },
    COMBATV2_ARCH_RELIC_BERSERKERS_FURY = {
        id = 36000, name = "Berserker's Fury",
        text = "Berserker's Fury - For all combat styles, deal up to 5.5% more damage the lower your current life points are below max health",
    },
    COMBATV2_ARCH_RELIC_CONSERVATION_OF_ENERGY = {
        id = 35993, name = "Conservation of Energy",
        text = "Conservation of Energy - After using an ultimate ability, you will regain 10% adrenaline",
    },
    COMBATV2_ARCH_RELIC_DEATH_WARD = {
        id = 36001, name = "Death Ward",
        text = "Death Ward - 5% damage reduction when your life points are below 50%; 10% damage reduction when they are below 25%",
    },
    COMBATV2_ARCH_RELIC_FURY_OF_THE_SMALL = {
        id = 35992, name = "Fury of the Small",
        text = "Fury of the Small - All basic abilities generate 1% more adrenaline",
    },
    COMBATV2_ARMOUR_BREAK_ABILITY = {
        id = 33651, name = "Armour Break",
        text = "Armour Break - Armour effectiveness is reduced by 1% per stack.",
    },
    COMBATV2_BARBASSAULT_INSIGNIA_ATTACK_DUMMY_ABILITY = {
        id = 24374, name = "Penance Attack",
        text = "Penance Attack - Inflicts 50 (500 if insignia was charged) damage every 3 seconds for 12 seconds",
    },
    COMBATV2_BEACH_DUNGEONEERING = {
        id = 45327, name = "Beach: Dungeoneering",
        text = "Your ability to delve into the 'Dungeoneering Hole' activity is improved.XP gain is increased by +10%.You can now complete '60 floors' before having to break.Doing the activity won't increase your temperature gauge.This effect lasts 15 mins.",
    },
    COMBATV2_BEACH_FISHING = {
        id = 45330, name = "Beach: Fishing",
        text = "Your ability to fish within the 'Rock Pools' is improved.XP gain is increased by +10%.This effect lasts 15 mins.",
    },
    COMBATV2_BEACH_HOOK_A_DUCK = {
        id = 45328, name = "Beach: Hook a Duck",
        text = "Your prowess at the 'Hook a Duck' activity is improved.XP gain is increased by +10%.This effect lasts 15 mins.",
    },
    COMBATV2_BEACH_PALM_TREES = {
        id = 45329, name = "Beach: Palm farming",
        text = "Your skill at picking coconuts from the 'Palm Tree Farming' activity is improved.XP gain is increased by +10%.Picking from trees no longer depletes fruit from the tree.This effect lasts 15 mins.",
    },
    COMBATV2_BEACH_SANDCASTLES = {
        id = 45331, name = "Beach: Sandcastles",
        text = "Your skill at the 'Sandcastle Building' activity is improved.XP gain is increased by +10%.You can shovel sand up to 60 times before you need a rest.This effect lasts 15 mins.",
    },
    COMBATV2_BEASTMASTER_ARMOUR_DEBUFF = {
        id = 35799, name = "Bitten",
        text = "Bitten - Each stack increases all damage taken.",
    },
    COMBATV2_BEASTMASTER_COMBUST_DEBUFF = {
        id = 35801, name = "Combust",
        text = "Combust - Each stack increases the bleed damage applied to you by Beastmaster Durzag's pets.",
    },
    COMBATV2_BEASTMASTER_RAGE_DEBUFF = {
        id = 35803, name = "Rage",
        text = "Rage - Each stack increases damage taken from Beastmaster Durzag.",
    },
    COMBATV2_BEASTMASTER_RUN_DEBUFF = {
        id = 35800, name = "Fatigued",
        text = "Fatigued - Each stack increases the run energy drained by each attack from Beastmaster Durzag's pets.",
    },
    COMBATV2_BLADED_DIVE_BOOTS_UPGRADE_BUFF_DUMMY_ABILITY = {
        id = 46272, name = "Empowered Barge",
        text = "Your next Barge ability is empowered.",
    },
    COMBATV2_BLADED_DIVE_BOOTS_UPGRADE_BUFF_DUMMY_ABILITY_COOLDOWN = {
        id = 46273, name = "Laceration boots CD",
        text = "Your laceration boots' empowering effect is on cooldown.",
    },
    COMBATV2_BLOOD_ESSENCE_COOLDOWN_DUMMY_ABILITY = {
        id = 35750, name = "Blood essence CD",
        text = "Bloodthirsty - Your body requires at least 60 seconds recovery time between Blood Essence activations.",
    },
    COMBATV2_BSLAY_ASCENDRI_BOLTS_DUMMY_ABILITY = {
        id = 24334, name = "Deathmark (bolts)",
        text = "Deathmark - gain an additional 1% adrenaline from basic abilities.",
    },
    COMBATV2_BSLAY_REAPER_NECKLACE_DUMMY_ABILITY = {
        id = 24333, name = "Reaper necklace",
        text = "Reaper Necklace - provides a 0.1% accuracy boost per stack",
    },
    COMBATV2_BUFF_DINO_BOSS_SHADOW_POWER = {
        id = 45036, name = "Inner power",
        text = "Inner power - Harnessing the shadow anima will increase damage dealt to Raksha. Damage is increased by 10% per stack.",
    },
    COMBATV2_BUFF_EGWD_BIK_MAGIC_ARMOUR_SHIELD_COOLDOWN = {
        id = 45357, name = "Fungal Shield CD",
        text = "Your Fungal Shield effect is on cooldown.",
    },
    COMBATV2_BUFF_EGWD_FUL_BOSS_CHALLENGERS_VENGEANCE = {
        id = 45558, name = "Challenger's Vengeance",
        text = "Challenger's Vengeance - You successfully completed TzKal-Zuk's challenge.",
    },
    COMBATV2_BUFF_EGWD_FUL_BOSS_INFERNAL_ENERGY = {
        id = 45557, name = "Igneous energy",
        text = "Igneous energy - The energy flows through your body.",
    },
    COMBATV2_BUFF_EGWD_JAS_BOSS_TIME_WARP = {
        id = 45399, name = "Warp Time",
        text = "Warp Time: Takes a snapshot of your life points, ability cooldowns, adrenaline, prayer points and location. 10 seconds later, you'll be restored to that point in time, exactly as you were.",
    },
    COMBATV2_BUFF_EXTRA_ACTION_ABILITY_KREEARRA = {
        id = 45402, name = "Swiftness of the Aviansie",
        text = "Swiftness of the Aviansie - Damage output is increased by 10%",
    },
    COMBATV2_BUFF_EXTRA_ACTION_ABILITY_ZILYANA = {
        id = 45401, name = "Light of Saradomin",
        text = "Light of Saradomin - Incoming damage is reduced by 50%",
    },
    COMBATV2_BUFF_GLACIAL_EMBRACE_COOLDOWN = {
        id = 44068, name = "Frost Surge CD",
        text = "Frost Surge - Currently on cooldown.",
    },
    COMBATV2_BUFF_LEAGUE_RELIC_COMBAT_LIGHT_STRIKE_COOLDOWN = {
        id = 3601, name = "Light Strike CD",
        text = "Light Strike is on cooldown.",
    },
    COMBATV2_BUFF_LEAGUE_RELIC_COMBAT_LORD_OF_LIGHT_COOLDOWN = {
        id = 3602, name = "Lord of Light CD",
        text = "Lord of Light is on cooldown.",
    },
    COMBATV2_BUFF_MAGIC_CRITICAL_STRIKE_ADRENALINE_EFFECT = {
        id = 48283, name = "Magic crit adrenaline",
        text = "Magic critical strikes generate an additional 8% adrenaline.",
    },
    COMBATV2_BUFF_MELEE_GREATER_FURY_GUARANTEED_CRITICAL_STRIKE = {
        id = 49534, name = "Guaranteed melee crit",
        text = "Your next Melee attack is guaranteed to Critically Strike.",
    },
    COMBATV2_BUFF_MELEE_METEOR_STRIKE_ADRENALINE_EFFECT = {
        id = 52776, name = "Melee adrenaline boost",
        text = "Melee basic abilities generate 1.5x adrenalineRegenerate 4.5% adrenaline every 0.6s.",
    },
    COMBATV2_BUFF_RANGED_CRITICAL_STRIKE_ADRENALINE_EFFECT = {
        id = 48285, name = "Ranged crit adrenaline",
        text = "Ranged critical strikes generate an additional 8% adrenaline.",
    },
    COMBATV2_BUFF_REXKINGS_MAGIC_SHOCKED = {
        id = 44999, name = "Overcharged",
        text = "Overcharged - Lightning runs through your veins, you will deal additional magic damage on each of your attacks and your surge ability has a drastically reduced cooldown.",
    },
    COMBATV2_BUFF_REXKINGS_MELEE_FROZEN = {
        id = 44997, name = "Frostbite",
        text = "Frostbite - You have been frozen to the core, reducing attack speed and movement speed.",
    },
    COMBATV2_BUFF_REXKINGS_MELEE_THAWED = {
        id = 44998, name = "Pyroclastic Shock",
        text = "Pyroclastic Shock - You have been rapidly defrosted, gaining a huge adrenaline rush!",
    },
    COMBATV2_BUFF_VAMPYRE_SLAYER = {
        id = 53442, name = "Vampyre Slayer",
        text = "Vampyre slayer - Boosts your damage against vampyric creatures by 15%.",
    },
    COMBATV2_BUFF_VITAL_DRAIN = {
        id = 53443, name = "Vital drain",
        text = "Vital drain - Steals health from enemies hit.",
    },
    COMBATV2_CALORIE_BOMB_DELOYED = {
        id = 33490, name = "Calorie bomb deploy CD",
        text = "Deployed a Calorie bomb",
    },
    COMBATV2_CALORIE_BOMB_RECIEVED_HEAL = {
        id = 33491, name = "Calorie bomb heal CD",
        text = "Healed by another player's Calorie bomb",
    },
    COMBATV2_CAMEL_SANDSTORM_DUMMY_ABILITY = {
        id = 30956, name = "Camel Sandstorm",
        text = "Camel Sandstorm - 5% reduced chance to hit",
    },
    COMBATV2_CANNON_TIMER = {
        id = 39039, name = "Cannon active",
        text = "Your cannon is active. Once the timer runs out, it will jam!",
    },
    COMBATV2_CHALLENGE_RETURNER_DXP_CHANCE_ABILITY = {
        id = 47454, name = "Double XP chance",
        text = "5% chance to double base XP",
    },
    COMBATV2_CHARGE_OVERRIDE_BUFF_DUMMY_ABILITY = {
        id = 40938, name = "Greater Barge ready",
        text = "Casting greater barge will make your next melee channelled ability instant and deal damage over time instead.",
    },
    COMBATV2_CHARMING_POTION_DUMMY_ABILITY = {
        id = 36921, name = "Charming potion",
        text = "Charming potion active - gives an extra charm per charm drop.",
    },
    COMBATV2_CHRONICLE_CARD_DUMMY_ABILITY = {
        id = 33215, name = "Chronicle XP boost",
        text = "Chronicle Card Collection - 5% XP boost",
    },
    COMBATV2_CRACKLING_PERK_ACTIVE = {
        id = 33544, name = "Crackling",
        text = "Your Crackling perk will activate on your next hit.",
    },
    COMBATV2_CRACKLING_PERK_COOLDOWN = {
        id = 33782, name = "Crackling CD",
        aliases = { "crackling cooldown", "crackling cd" },
        text = "Your Crackling perk will not activate while this is up.",
    },
    COMBATV2_CRAFTING_POTION_EFFECT = {
        id = 50247, name = "Crafting potion",
        text = "Crafting Potion Active - increases your Crafting level temporarily.",
    },
    COMBATV2_CRUC_DM_APPLY_THERMAL_HEALTH_BOOST = {
        id = 31919, name = "Thermal bath",
        text = "Thermal bath - maximum health is increased.",
    },
    COMBATV2_DEBUFF_EGWD_FUL_BOSS_HEATING_UP = {
        id = 45561, name = "Heating Up",
        text = "Heating Up - You're hot enough to be able to damage TzKal-Zuk's spire!",
    },
    COMBATV2_DEBUFF_EGWD_FUL_BOSS_INFERNAL_BURN = {
        id = 45559, name = "Geothermal Burn",
        text = "Geothermal Burn - The burn is causing moderate damage.",
    },
    COMBATV2_DEBUFF_EGWD_FUL_BOSS_SEARING_PAIN = {
        id = 45560, name = "Searing Pain",
        text = "Searing Pain - The suffering is reducing your maximum life points.",
    },
    COMBATV2_DEBUFF_LEAGUE_RELIC_DEBUFF_SLIVER_OF_EDICTS = {
        id = 3596, name = "Sliver of Edicts CD",
        text = "Sliver of Edicts - Currently on cooldown.",
    },
    COMBATV2_DEBUFF_POWERBURST_COOLDOWN = {
        id = 920, name = "Powerburst CD",
        aliases = { "powerburst cooldown" },
        text = "Powerburst potion is on cooldown.",
    },
    COMBATV2_DETONATE_CHARGEUP = {
        id = 35816, name = "Detonate",
        text = "Detonate is charging; upon hitting 100%, detonate it for maximum damage.",
    },
    COMBATV2_DEVOTED_PERK = {
        id = 35806, name = "Devoted",
        text = "Devoted - Protection prayers are 100% effective (75% in PvP) for 3 seconds.",
    },
    COMBATV2_DINARROW_BIK_DUMMY_ABILITY = {
        id = 43673, name = "Evolving Toxin",
        text = "Evolving Toxin: Increases poison damage taken by percentage displayed. After 30 seconds without an ability using a Bik arrow hitting the target, all stacks are removed.",
    },
    COMBATV2_DINARROW_WEN_CHILL_DUMMY_ABILITY = {
        id = 43678, name = "Icy Chill",
        text = "Icy Chill: At 10 stacks non-basic abilities convert this into Icy Precision for 9s.",
    },
    COMBATV2_DINARROW_WEN_PRECISION_DUMMY_ABILITY = {
        id = 43682, name = "Icy Precision",
        text = "Icy Precision: Blocks consumption of Icy Chill and gives threshold, ultimate and special abilities +30% base damage and +30% hit chance.",
    },
    COMBATV2_DINO_GAME_ENCOUNTER_COOLDOWN_1 = {
        id = 30522, name = "Arcane apoterrasaur CD",
        text = "The arcane apoterrasaur are currently in hiding.",
    },
    COMBATV2_DINO_GAME_ENCOUNTER_COOLDOWN_2 = {
        id = 30758, name = "Scimitops CD",
        text = "The scimitops are currently in hiding.",
    },
    COMBATV2_DINO_GAME_ENCOUNTER_COOLDOWN_3 = {
        id = 30759, name = "Bagrada rex CD",
        text = "The bagrada rex are currently in hiding.",
    },
    COMBATV2_DINO_GAME_ENCOUNTER_COOLDOWN_4 = {
        id = 30821, name = "Spicati apoterrasaur CD",
        text = "The spicati apoterrasaur are currently in hiding.",
    },
    COMBATV2_DINO_GAME_ENCOUNTER_COOLDOWN_5 = {
        id = 30828, name = "Asciatops CD",
        text = "The asciatops are currently in hiding.",
    },
    COMBATV2_DINO_GAME_ENCOUNTER_COOLDOWN_6 = {
        id = 30964, name = "Corbicula rex CD",
        text = "The corbicula rex are currently in hiding.",
    },
    COMBATV2_DINO_GAME_ENCOUNTER_COOLDOWN_7 = {
        id = 31386, name = "Oculi apoterrasaur CD",
        text = "The oculi apoterrasaur are currently in hiding.",
    },
    COMBATV2_DINO_GAME_ENCOUNTER_COOLDOWN_8 = {
        id = 31562, name = "Malletops CD",
        text = "The malletops are currently in hiding.",
    },
    COMBATV2_DINO_GAME_ENCOUNTER_COOLDOWN_9 = {
        id = 31918, name = "Pavosaurus rex CD",
        text = "The pavosaurus rex are currently in hiding.",
    },
    COMBATV2_DINO_SLAYER_TOXIC_EFFECT = {
        id = 31920, name = "Toxic",
        text = "Toxic - a deadly venom flows through your veins dealing rapid damage.",
    },
    COMBATV2_DIVCHAMBER_BOOST_DUMMY_ABILITY = {
        id = 40237, name = "Blessing of recollection",
        text = "Blessing of recollection - A chance to obtain memory shards when harvesting in the Hall of Memories.",
    },
    COMBATV2_DIVDND_REWARD_DUMMY_ABILITY = {
        id = 29340, name = "Guthix cache boost",
        text = "Guthix cache boosts - 10% chance to double loot from divine locations, save a charge from a sign of the porter and convert all memories at once.",
    },
    COMBATV2_DIV_CRATER_EVENT_BUFF_DUMMY_ABILITY = {
        id = 32590, name = "Memory Overflow",
        text = "Memory Overflow - +10% crit chance when siphoning springs; +5% XP and +1 energy when depositing memories.",
    },
    COMBATV2_DREADNIP_DUMMY_ABILITY = {
        id = 35751, name = "Dreadnip",
        text = "Dreadnip active - A ferocious pest is attacking your target.",
    },
    COMBATV2_DSF_JELLYFISH_STUN_DUMMY_ABILITY = {
        id = 39440, name = "Jellyfish shock",
        text = "Deep Sea Fishing - Electrified stacks can be removed by catching regular jellyfish. If you continue to fish from electrifying jellyfish with 10 stacks, the jellyfish will stun you and you will not be able to remove this debuff for a period of time.",
    },
    COMBATV2_DSF_REWARD_BOOST_1_DUMMY_ABILITY = {
        id = 39437, name = "DSF: catch rate",
        text = "Deep Sea Fishing - A 10% increase to your fishing catch rate.",
    },
    COMBATV2_DSF_REWARD_BOOST_2_DUMMY_ABILITY = {
        id = 39438, name = "DSF: extra catch",
        text = "Deep Sea Fishing - A 10% chance to gain an additional catch.",
    },
    COMBATV2_DSF_REWARD_BOOST_3_DUMMY_ABILITY = {
        id = 39439, name = "DSF: Fishing XP",
        text = "Deep Sea Fishing - An additional 5% Fishing XP.",
    },
    COMBATV2_DUNGEON_AMINISHI_BOSS2_WATER_BUFF_DUMMY_ABILITY = {
        id = 40525, name = "Calm Waters",
        text = "Calm Waters - Provides some protection against water damage received from Masuta the Ascended.",
    },
    COMBATV2_DUNGEON_DRAGONFORT_BOSS1_WYRMHOLE_BUFF_DUMMY_ABILITY = {
        id = 40940, name = "Phase Space",
        text = "Phase Space - Your attacks against Astellarn are boosted.",
    },
    COMBATV2_DUNGEON_ULTHVEN_DEMON_SLAYER_DUMMY_ABILITY = {
        id = 37218, name = "Demon Slayer",
        text = "Demon slayer - Boosts your damage against demons by 15%.",
    },
    COMBATV2_DUNGEON_ULTHVEN_DRAGON_SLAYER_DUMMY_ABILITY = {
        id = 37219, name = "Dragon Slayer",
        text = "Dragon slayer - Boosts your damage against dragons by 15%.",
    },
    COMBATV2_DUNGEON_ULTHVEN_UNDEAD_SLAYER_DUMMY_ABILITY = {
        id = 37217, name = "Undead Slayer",
        text = "Undead slayer - Boosts your damage against the undead by 15%.",
    },
    COMBATV2_EGWD_BIK_BOSS_ATTUNED_FISHING = {
        id = 45102, name = "Fishing attunement",
        text = "Fishing Attuned - Improved efficiency when fishing. Reduced efficiency when woodcutting.",
    },
    COMBATV2_EGWD_BIK_BOSS_ATTUNED_HUNTER = {
        id = 42661, name = "Hunter attunement",
        text = "Hunter Attuned - Improved efficiency when hunting. Reduced efficiency when fishing.",
    },
    COMBATV2_EGWD_BIK_BOSS_ATTUNED_MINING = {
        id = 42125, name = "Mining attunement",
        text = "Mining Attuned - Improved efficiency when mining. Reduced efficiency when hunting.",
    },
    COMBATV2_EGWD_BIK_BOSS_ATTUNED_WOODCUTTING = {
        id = 40790, name = "Woodcutting attunement",
        text = "Woodcutting Attuned - Improved efficiency when woodcutting. Reduced efficiency when mining.",
    },
    COMBATV2_EGWD_ZAMORAK_BOSS_FLAMES_OF_ZAMORAK_ERUPTION_STACKS = {
        id = 41806, name = "Flames of Zamorak",
        text = "Flames of ZamorakThe power of Zamorak's flames causes a delayed eruption of chaos fire.Each stack will melt through any active shielding.",
    },
    COMBATV2_EGWD_ZAMORAK_BOSS_INFERNUS_CHOKING = {
        id = 41787, name = "Choking",
        text = "Choking - While on Infernus, you struggle to breathe, dealing less and taking more damage per stack.",
    },
    COMBATV2_EGWD_ZAMORAK_BOSS_RUNE_DEFENSIVE_CLEANSING_BUFF_COOLDOWN = {
        id = 41805, name = "Cleansing Aura CD",
        text = "Cleansing Aura - Cooldown",
    },
    COMBATV2_ENHANCED_DEVOTED_PERK = {
        id = 35807, name = "Enhanced Devoted",
        text = "Enhanced Devoted - Protection prayers are 100% effective (75% in PvP) for 3 seconds.",
    },
    COMBATV2_EVENT21_JEWELLERY_BUFF = {
        id = 11590, name = "Jewellery event boost",
        text = "For the event's duration+250% XP when smelting gold and silver bars50% faster gold and silver smelting33% faster gold and silver casting.",
    },
    COMBATV2_EVENT21_MINING_BUFF = {
        id = 11589, name = "Mining event boost",
        text = "For the event's duration+50% XP when mining gold and silver rocksMining clay now gives soft clay instead.",
    },
    COMBATV2_EVENT21_URN_BUFF = {
        id = 11591, name = "Urn crafting event boost",
        text = "For the event's duration50% faster crafting using the pottery wheel80% faster crafting using the pottery oven+100% XP when crafting urns.",
    },
    COMBATV2_EVENT_CRAFTING_FISHING_ITEM_XP_ENHANCER = {
        id = 44432, name = "Fishing item XP",
        text = "Increases the item experience you gain while fishing by 50% for 10 minutes.",
    },
    COMBATV2_EVENT_CRAFTING_FISHING_PERK_ENHANCER = {
        id = 44431, name = "Fishing perk boost",
        text = "Doubles the activation chance of perks on your tool while fishing for 10 minutes.",
    },
    COMBATV2_EVENT_CRAFTING_FISH_FLINGER_ENHANCER = {
        id = 44430, name = "Fish Flingers rewards",
        text = "Doubles the amount of tokens & medals you receive from Fish flingers for 15 minutes.",
    },
    COMBATV2_EVENT_CRAFTING_FLETCHING_MAKE_X_MAX_ENHANCER = {
        id = 44340, name = "Fletching batch +15",
        text = "Boosts the maximum amount of items you can make while fletching by 15 for 10 minutes.",
    },
    COMBATV2_EVENT_CRAFTING_FLETCHING_MAKE_X_MAX_LARGE_ENHANCER = {
        id = 44341, name = "Fletching batch +30",
        text = "Boosts the maximum amount of items you can make while fletching by 30 for 10 minutes.",
    },
    COMBATV2_EVENT_CRAFTING_FLETCHING_RESOURCE_ENHANCER = {
        id = 44342, name = "Fletching resource saver",
        text = "Gives you a 10% chance to save resources while fletching for 10 minutes.",
    },
    COMBATV2_EVENT_CRAFTING_MINING_CRIT_ENHANCER = {
        id = 44434, name = "Mining crit boost",
        text = "Increases your chance to critically strike a mining rock by 10% for 10 minutes.",
    },
    COMBATV2_EVENT_CRAFTING_MINING_GEODE_ENHANCER = {
        id = 44433, name = "Mining geode boost",
        text = "Increases your chance to obtain geodes while mining by 10% for 10 minutes.",
    },
    COMBATV2_EVENT_CRAFTING_SMITHING_LUMINITE_ENHANCER = {
        id = 44343, name = "Luminite injector boost",
        text = "Triples the effectiveness of luminite injectors on you for 10 minutes.",
    },
    COMBATV2_EVENT_CRAFTING_SMITHING_RESPECT_ENHANCER = {
        id = 44344, name = "Double workshop respect",
        text = "Doubles all your respect gain within the artisans workshop for 10 minutes.",
    },
    COMBATV2_EVENT_CRAFTING_WOODCUTTING_ITEM_XP_ENHANCER = {
        id = 44429, name = "Woodcutting item XP",
        text = "Increases the item experience you gain while woodcutting by 50% for 10 minutes.",
    },
    COMBATV2_EVENT_CRAFTING_WOODCUTTING_PERK_ENHANCER = {
        id = 44428, name = "Woodcutting perk boost",
        text = "Doubles the activation chance of perks on your tool while woodcutting for 10 minutes.",
    },
    COMBATV2_EVILTREE_BANKING = {
        id = 39027, name = "Evil Tree log banking",
        text = "You are granted a magical log-banking ability, banking any logs you chop.",
    },
    COMBATV2_EXCALIBUR_ACTIVE = {
        id = 35748, name = "Excalibur CD",
        aliases = { "enhanced excalibur cooldown", "excalibur cooldown" },
        text = "Enhanced Excalibur - Currently on cooldown.",
    },
    COMBATV2_EXTREME_COOKING_DUMMY_ABILITY = {
        id = 36919, name = "Extreme cooking",
        text = "Extreme Cooking Potion Active - increases your Cooking level temporarily.",
    },
    COMBATV2_EXTREME_DIVINATION_DUMMY_ABILITY = {
        id = 41145, name = "Extreme divination",
        text = "Extreme Divination Potion Active - increases your Divination level temporarily.",
    },
    COMBATV2_EXTREME_HUNTING_DUMMY_ABILITY = {
        id = 41148, name = "Extreme hunter",
        text = "Extreme Hunter Potion Active - increases your Hunter level temporarily.",
    },
    COMBATV2_EXTREME_INVENTION_DUMMY_ABILITY = {
        id = 41147, name = "Extreme invention",
        text = "Extreme Invention Potion Active - increases your Invention level temporarily.",
    },
    COMBATV2_EXTREME_RUNECRAFTING_DUMMY_ABILITY = {
        id = 41146, name = "Extreme runecrafting",
        text = "Extreme Runecrafting Potion Active - increases your Runecrafting level temporarily.",
    },
    COMBATV2_FAMILIARISATION_DUMMY_ABILITY = {
        id = 30869, name = "Triple charms",
        text = "Familiarisation - Triple charms active",
    },
    COMBATV2_FARM_REQ_BRASSICA_PRIMER_STRUCT = {
        id = 36923, name = "Brassica primer",
        text = "Brassica Primer - gives a 10% XP boost when checking the health of Farming patches",
    },
    COMBATV2_FIGHTKILN_HITPOINTS = {
        id = 39035, name = "Kiln: Constitution",
        text = "This crystal will increase your Constitution.",
    },
    COMBATV2_FIGHTKILN_INVULN = {
        id = 39031, name = "Kiln: Invulnerability",
        text = "This crystal will make you temporarily invulnerable.",
    },
    COMBATV2_FIGHTKILN_MAGIC = {
        id = 39032, name = "Kiln: Magic",
        text = "This crystal will increase your Magic prowess, but decreases Defence, Strength and Ranged.",
    },
    COMBATV2_FIGHTKILN_RANGED = {
        id = 39033, name = "Kiln: Ranged",
        text = "This crystal will increase your Ranged ability, but decreases Defence, Strength and Magic.",
    },
    COMBATV2_FIGHTKILN_STRENGTH = {
        id = 39034, name = "Kiln: Strength",
        text = "This crystal will increase your Strength, but decreases Defence, Ranged and Magic.",
    },
    COMBATV2_FURY_SHARK_ACTIVE = {
        id = 37420, name = "Fury shark protection",
        text = "Your fury shark has been consumed and will protect an item for one minute.",
    },
    COMBATV2_GAMEMODE_SEASONAL_REWARD_PORTER_DUMMY_ABILITY = {
        id = 34990, name = "Challenger porter",
        text = "Your challenger porter is active and has a 50% chance to bank specific items.",
    },
    COMBATV2_GAMEMODE_SEASONAL_XP_BOOST_DUMMY_ABILITY = {
        id = 35070, name = "Fresh Start Worlds XP",
        text = "During this week of Fresh Start Worlds, you are earning extra XP.",
    },
    COMBATV2_GLOVES_OF_PASSING_EFFECT = {
        id = 37659, name = "Gloves of Passage",
        text = "Gloves of Passage - Your next melee attack within 6 seconds deals 10% increased damage.",
    },
    COMBATV2_GORAJIAN_MUSHROOM_EFFECT = {
        id = 35811, name = "Gorajian mushroom",
        text = "Damage in PvP is reduced by 15%.",
    },
    COMBATV2_GORAJIAN_MUSHROOM_TIMER = {
        id = 35812, name = "Gorajian mushroom CD",
        text = "Your Gorajian mushroom effect is on cooldown.",
    },
    COMBATV2_GWD2_SOLO_BLACK_DOT_DUMMY_ABILITY = {
        id = 33656, name = "Black virus",
        text = "A black virus is affecting you, dealing rapid damage. If you don't clear it when the effect runs out you'll be dealt heavy damage.",
    },
    COMBATV2_GWD2_SOLO_BLACK_STREAM_DUMMY_ABILITY = {
        id = 33653, name = "Black stream",
        text = "Black stream - reduces damage taken and damage dealt.",
    },
    COMBATV2_GWD2_SOLO_BLUE_DOT_DUMMY_ABILITY = {
        id = 28853, name = "Blue virus",
        text = "A blue virus is affecting you, dealing rapid damage. If you don't clear it when the effect runs out you'll be dealt heavy damage.",
    },
    COMBATV2_GWD2_SOLO_BLUE_STREAM_DUMMY_ABILITY = {
        id = 27829, name = "Blue stream",
        text = "Blue stream - gaining adrenaline, losing prayer points.",
    },
    COMBATV2_GWD2_SOLO_GREEN_DOT_DUMMY_ABILITY = {
        id = 33655, name = "Green virus",
        text = "A green virus is affecting you, dealing rapid damage. If you don't clear it when the effect runs out you'll be dealt heavy damage.",
    },
    COMBATV2_GWD2_SOLO_GREEN_STREAM_DUMMY_ABILITY = {
        id = 33652, name = "Green stream",
        text = "Green stream - gaining adrenaline, losing prayer points.",
    },
    COMBATV2_GWD2_SOLO_RED_DOT_DUMMY_ABILITY = {
        id = 33657, name = "Red virus",
        text = "A red virus is affecting you, dealing rapid damage. If you don't clear it when the effect runs out you'll be dealt heavy damage.",
    },
    COMBATV2_GWD2_SOLO_RED_STREAM_DUMMY_ABILITY = {
        id = 33654, name = "Red stream",
        text = "Red stream - increases damage dealt and damage taken.",
    },
    COMBATV2_HALLOWEEN23_CANDY_ENHANCER_ARCH = {
        id = 48846, name = "Archaeology candy",
        text = "+50% base Archaeology precision.+100% XP from sprite focus buff.+1 material at 100% sprite focus.Lasts 10 minutes.",
    },
    COMBATV2_HALLOWEEN23_CANDY_ENHANCER_DIVINATION = {
        id = 48849, name = "Divination candy",
        text = "+25% critical chance for Divination.+100% base energy when harvesting from a Divination spring.+50% energy when converting memories to energy.Lasts 10 minutes.",
    },
    COMBATV2_HALLOWEEN23_CANDY_ENHANCER_FIREMAKING = {
        id = 48847, name = "Firemaking candy",
        text = "+100% chance to spawn fire spirits whilst Firemaking.When claiming a fire spirit, gain 100% base Firemaking XP of the log burnt to spawn it.Automatically claims fire spirits when they spawn.Lasts 10 minutes.",
    },
    COMBATV2_HALLOWEEN23_CANDY_ENHANCER_LUCK = {
        id = 48848, name = "Luck candy",
        text = "Grants tier 4 luck whilst active. This bonus is capped at tier 1 in free to play worlds.Lasts 10 minutes.",
    },
    COMBATV2_HALLOWEEN23_CANDY_ENHANCER_POWERUP = {
        id = 48850, name = "Pumpkin auto-smash",
        text = "Automatically smash pumpkins when they spawn.Consumes 1 stack per use.Grants 5 stacks.",
    },
    COMBATV2_HALLOWEEN23_CANDY_ENHANCER_PRAYER = {
        id = 48845, name = "Prayer candy",
        text = "+25% chance to save bones and ashes offered on an altar.-33% delay between offering on an altar.Lasts 10 minutes.",
    },
    COMBATV2_HALLOWEEN23_CANDY_ENHANCER_SLAYER = {
        id = 48844, name = "Slayer candy",
        text = "+5% Slayer XP.+25% chance not to decrease Slayer count on target kill.Lasts 10 minutes.",
    },
    COMBATV2_HARVEST_POTION_TIMER = {
        id = 36920, name = "Harvest potion",
        text = "Harvest Potion Active - allows you to discover special produce from your allotments patches.",
    },
    COMBATV2_HOOKS3_XP_DEBUFF_DUMMY_ABILITY = {
        id = 52318, name = "Wicked XP lock",
        text = "Wicked - Blocks any XP boosts from the savvy runecrafting levelling benefit.",
    },
    COMBATV2_IDOLS_BUFF_1_DUMMY_ABILITY = {
        id = 40032, name = "Idol: cut speed",
        text = "Overgrown idol - Woodcutting cut rate is doubled.",
    },
    COMBATV2_IDOLS_BUFF_2_DUMMY_ABILITY = {
        id = 40033, name = "Idol: success rate",
        text = "Overgrown idol - A 10% increase to your Woodcutting success rate.",
    },
    COMBATV2_IDOLS_BUFF_3_DUMMY_ABILITY = {
        id = 40034, name = "Idol: extra logs",
        text = "Overgrown idol - A 10% chance to gain an additional log or cut an additional time.",
    },
    COMBATV2_IDOLS_BUFF_4_DUMMY_ABILITY = {
        id = 40035, name = "Idol: Woodcutting XP",
        text = "Overgrown idol - An additional 5% Woodcutting XP.",
    },
    COMBATV2_IDOLS_BUFF_5_DUMMY_ABILITY = {
        id = 40036, name = "Idol: log banking",
        text = "Overgrown idol - Any logs chopped will be magically sent to the bank.",
    },
    COMBATV2_INFINITE_RUN = {
        id = 39392, name = "Infinite run",
        text = "You currently feel energised and hastened.",
    },
    COMBATV2_INGENUITY_OF_THE_HUMANS_DUMMY_ABILITY = {
        id = 37216, name = "Ingenuity of the Humans",
        text = "Ingenuity of the Humans - The next strike from an ability you use is guaranteed to hit.",
    },
    COMBATV2_INTERCEPT_GIVEN = {
        id = 34747, name = "Intercept",
        text = "Intercept - You will receive redirected damage.",
    },
    COMBATV2_INTERCEPT_RECEIVED = {
        id = 35314, name = "Intercepted",
        text = "Intercepted - You will receive no damage.",
    },
    COMBATV2_INVENT_GENOCIDAL = {
        id = 39038, name = "Genocidal",
        text = "Your Genocidal perk is active in this Slayer Task, allowing you to deal up to 5% extra damage depending on how far you are through your Slayer task.",
    },
    COMBATV2_INVENT_PERK_RUTHLESS_DUMMY_ABILITY = {
        id = 35990, name = "Ruthless",
        aliases = { "ruthless" },
        text = "Ruthless - whenever you defeat an enemy you gain a 0.5% damage boost per rank for 20 seconds.",
    },
    COMBATV2_LORE_ANCIENT_KALGERION_DEMON_SCROLL_DUMMY_ABILITY = {
        id = 35968, name = "Kal'gerion roar",
        text = "Kal'gerion roar - +5% Critical Strike Chance.",
    },
    COMBATV2_LORE_DIG_FOR_SOIL_DUMMY_ABILITY = {
        id = 53003, name = "Dig for Soil",
        text = "Dig for Soil - Increases your chance of finding soil by 10% while excavating.",
    },
    COMBATV2_LORE_ENLIGHTENMENT_DUMMY_ABILITY = {
        id = 32116, name = "Enlightenment",
        text = "Enlightenment- Better rewards on the Hefin Agility Course- Increases the instant memory conversion chance to 50%- Gives a 10% chance of getting double blue tears in Tears of Guthix",
    },
    COMBATV2_LUNAR_TUNE_BANE_ORE = {
        id = 44698, name = "Tune Bane Ore",
        text = "Tune bane ore - You have currently tuned bane rocks.",
    },
    COMBATV2_MELEE_CHANNEL_TO_DOT_BUFF_DUMMY_ABILITY = {
        id = 40939, name = "Endless Assault",
        text = "Endless Assault - Your next melee channelled ability will be instant cast and deal damage over time to your opponent instead.",
    },
    COMBATV2_MENAPHOS_CORRUPTION = {
        id = 23174, name = "Corrupted",
        text = "Corrupted - Damage dealt and damage taken is increased by 1% per stack",
    },
    COMBATV2_MENAPHOS_GOLDEN_TOUCH_DUMMY_ABILITY = {
        id = 37208, name = "Golden Touch",
        text = "Golden Touch - All alchable items (under your loot beam value) that drop for the next 60 seconds will be automatically high-alched",
    },
    COMBATV2_MENAPHOS_LIMITLESS_DUMMY_ABILITY = {
        id = 37214, name = "Limitless",
        text = "Limitless - You are no longer required to reach 50% adrenaline to use threshold abilities",
    },
    COMBATV2_MENAPHOS_SOUL_DRAIN = {
        id = 23175, name = "Soul drained",
        text = "Soul drained - Each stack reduces your maximum health by 100 lifepoints",
    },
    COMBATV2_MENAPHOS_UNSULLIED_DUMMY_ABILITY = {
        id = 37215, name = "Unsullied",
        text = "Unsullied - While corrupted you will no longer take additional damage in the Sophanem Slayer Dungeon",
    },
    COMBATV2_MENAPHOS_XPBOOST = {
        id = 37425, name = "Menaphos XP",
        text = "You are receiving a 5% XP boost for activities in Menaphos and the Sophanem Slayer Dungeon.",
    },
    COMBATV2_MHAW_MAY21_STONE_DUMMY_ABILITY = {
        id = 4574, name = "Rock of Resilience",
        text = "Rock of Resilience - 4% XP Boost",
    },
    COMBATV2_MINING_BANKING = {
        id = 39028, name = "Stone spirit banking",
        text = "A stone spirit has appeared offering to help you out!",
    },
    COMBATV2_MOLE2_MUDSTUN_DUMMY_ABILITY = {
        id = 25687, name = "Trapped in mud",
        text = "You've been trapped in mud! Get a friend to help you!",
    },
    COMBATV2_MTX_ANNIVERSARY20_10_PERCENT_AREA_BOOST_DURATION_DUMMY_ABILITY = {
        id = 45166, name = "Grand Party XP",
        text = "You are earning 10% more XP in this area while the Grand Party is active.",
    },
    COMBATV2_MTX_EASTER_2021_AREA_BOOST_DURATION_DUMMY_ABILITY = {
        id = 39632, name = "Spring Festival XP",
        text = "You are earning 2% more XP in this area while the Spring Festival is active.",
    },
    COMBATV2_MTX_EVENT16_10_PERCENT_AREA_BOOST_DUMMY_ABILITY = {
        id = 44234, name = "Storm area XP",
        text = "You are earning 10% more XP in this area while the Breaking the Storm event is active.",
    },
    COMBATV2_MTX_EVENT16_BOOST_JUICE_DURATION_DUMMY_ABILITY = {
        id = 11652, name = "Storm brew DXP",
        text = "You are currently earning Double XP while training at the Breaking the Storm event.",
    },
    COMBATV2_MTX_EVENT16_PASSIVE_BOOST_DUMMY_ABILITY = {
        id = 44233, name = "Storm supplies + DXP",
        text = "You are currently earning boat materials and gaining Double XP while training at the Breaking the Storm event.",
    },
    COMBATV2_MTX_EVENT17_10_PERCENT_AREA_BOOST_DURATION_DUMMY_ABILITY = {
        id = 36800, name = "Winter Chill Off XP",
        text = "You are earning 10% more XP in this area while the Winter Chill Off event is active.",
    },
    COMBATV2_MTX_EVENT21_10_PERCENT_CRAFTING_AREA_BOOST_DURATION_DUMMY_ABILITY = {
        id = 11588, name = "Crafting Guild: Crafting",
        text = "You are earning 10% more XP in crafting within the crafting guild while the master crafting event is going on. (This effect stacks with the overall +5% XP buff)",
    },
    COMBATV2_MTX_EVENT21_5_PERCENT_AREA_BOOST_DURATION_DUMMY_ABILITY = {
        id = 11570, name = "Crafting Guild: all XP",
        text = "You are earning 5% more XP in all skills within the crafting guild while the master crafting event is going on.",
    },
    COMBATV2_MTX_JAN20_BONFIRE_10_PERCENT_AREA_BOOST_DURATION_DUMMY_ABILITY = {
        id = 4546, name = "Wintumber Warmer XP",
        text = "You are earning 10% more XP in this area while the Wintumber Warmer event is active.",
    },
    COMBATV2_MTX_XP_BOMB_DUMMY_100_ABILITY = {
        id = 44062, name = "Knowledge bomb (+100%)",
        text = "You are currently earning 100% extra XP.",
    },
    COMBATV2_MTX_XP_BOMB_DUMMY_ABILITY = {
        id = 45168, name = "Knowledge bomb (+50%)",
        text = "You are currently earning 50% extra XP.",
    },
    COMBATV2_MTX_XP_BOMB_DUMMY_DXP_ABILITY = {
        id = 625, name = "Double XP",
        text = "You are currently earning Double XP. All standard DXP rules and caveats apply.",
    },
    COMBATV2_NATURE_BOSS_NO_HEALS = {
        id = 40126, name = "Withering",
        text = "Withering - Whilst suffering from withering you may not heal from food or potions.",
    },
    COMBATV2_NATURE_BOSS_PRAYER_RESTORER_ACTIVE = {
        id = 40899, name = "Ritual shard CD",
        text = "Ancient elven ritual shard - Currently on cooldown.",
    },
    COMBATV2_NEX2_RAGE_DEBUFF = {
        id = 35817, name = "Nex defensive resets",
        text = "Nex will reset your defensive abilities at 5, 10 & 15 stacks.",
    },
    COMBATV2_PIRATEFINALE_DRUNKENESS = {
        id = 39572, name = "Intoxication",
        text = "You are intoxicated. Higher intoxication can lead to vomiting and fatal alcohol poisoning.",
    },
    COMBATV2_PIRATEFINALE_INSANITY = {
        id = 39571, name = "Insanity",
        text = "You are starting to lose your mind. The higher your insanity the more dangerous the fight.",
    },
    COMBATV2_PLAYER_FORT_PERFECT_BUILD_DUMMY_ABILITY = {
        id = 34898, name = "Perfect Build",
        text = "Perfect Build- Modifies base experience gained constructing a building blueprint within Fort Forinthry by  3% for every 5% of Perfect Build.- Building at a non-optimal hotspot will deplete this.",
    },
    COMBATV2_PORTENT_RESTORATION = {
        id = 35815, name = "Restoration portent CD",
        text = "Your Portent of Restoration has recently activated, it'll activate again when off cooldown.",
    },
    COMBATV2_PORTSARIM_CONCH_DUMMY_ABILITY = {
        id = 33795, name = "Port Sarim conch",
        text = "Conch! Raid on Port Sarim bonus",
    },
    COMBATV2_PRAYER_DEBUFF = {
        id = 37423, name = "Protection prayer lock",
        text = "You are unable to use overhead protection prayers and deflection curses.",
    },
    COMBATV2_PRAYER_RATE = {
        id = 39025, name = "Prayer drain",
        text = "You have a prayer active, draining your prayer points.",
    },
    COMBATV2_PULSE_ESSENCE_DUMMY_ABILITY = {
        id = 30925, name = "Pulse core",
        text = "Pulse Core - 2% XP Boost",
    },
    COMBATV2_QUEST_DM_ARCH_FOCUS_BUFF = {
        id = 44596, name = "Cosmic accumulator",
        text = "Stasis chamber fragment boost: Provides extra sprite focus.",
    },
    COMBATV2_REVIVE_LIFE_EFFECT = {
        id = 35810, name = "Life protection CD",
        text = "You will not benefit from another Sign/Portent of Life for one hour; this also applies to the Defence skillcape.",
    },
    COMBATV2_RUNEPASS_XP_BOOST_DUMMY_ABILITY = {
        id = 45536, name = "Yak Track XP",
        text = "Yak Track - 1% XP Boost",
    },
    COMBATV2_SEREN_SET_EFFECT_DUMMY = {
        id = 24408, name = "Harmonious Resonance",
        text = "Harmonious Resonance - Seren prayers don't drain. Doubles the effectiveness of aurora spells",
    },
    COMBATV2_SHOOTING_STAR_BUFF = {
        id = 39036, name = "Shooting Star ore boost",
        text = "When mining, you have a 25% chance of getting double ore.",
    },
    COMBATV2_SLOW_SUM_COMMUNION_DUMMY_ABILITY = {
        id = 53001, name = "Spirit Communion",
        text = "Spirit Communion - Speeds up infusing pouches by 0.6 seconds. Stops spirit plane connection from decreasing.",
    },
    COMBATV2_SOLAK_CORRUPTION_STACKS = {
        id = 40124, name = "Blight",
        text = "Blight - Take 1% extra damage for each stack accumulated.",
    },
    COMBATV2_SPIDER_BOOST_1_DUMMY_ABILITY = {
        id = 41143, name = "NopeNopeNope I",
        text = "Your NopeNopeNope perk tier 1 allows you to deal 2% bonus damage to this monster.",
    },
    COMBATV2_SPIDER_BOOST_2_DUMMY_ABILITY = {
        id = 41144, name = "NopeNopeNope II",
        text = "Your NopeNopeNope perk tier 2 allows you to deal 3% bonus damage to this monster.",
    },
    COMBATV2_STAFF_OF_DARKNESS = {
        id = 44854, name = "Staff of darkness",
        text = "Reduces all incoming damage by 25% and 25% of incoming damage is reflected back to the attacker.",
    },
    COMBATV2_STAFF_OF_LIGHT = {
        id = 44853, name = "Staff of light",
        text = "Reduce all incoming melee damage by 50%",
    },
    COMBATV2_STUN_IMMUNE_ACTIVE = {
        id = 35749, name = "Stun immunity",
        text = "You are immune to all stuns for 15 seconds.",
    },
    COMBATV2_SUPER_MINING_POTION_EFFECT = {
        id = 50248, name = "Super mining",
        text = "Super Mining Potion Active - increases your Mining level temporarily.",
    },
    COMBATV2_TEAFLASK_COOLDOWN = {
        id = 39391, name = "Tea flask CD",
        text = "Your tea flask is currently reheating.",
    },
    COMBATV2_TELEBLOCKED = {
        id = 39030, name = "Teleport Block",
        text = "Teleport Block - Prevents teleporting using any spells or items.",
    },
    COMBATV2_TOMBS_BOOST = {
        id = 37424, name = "Shifting Tombs power-up",
        text = "Every five urns smashed will provide a power-up stack. While powered-up, you can smash through crystallised corruption with ease. The effect stacks up to three times.",
    },
    COMBATV2_TOPAZ_DEBUFF_DUMMY = {
        id = 39140, name = "Down to Earth",
        text = "Down to Earth - Each stack lowers magic damage by 1%.",
    },
    COMBATV2_TRH165_BXP_BURN_BOOST_DUMMY_ABILITY = {
        id = 34338, name = "Cinder core",
        text = "Cinder Core - 2% Bonus XP Burn Boost",
    },
    COMBATV2_TRH_PROTEAN_EXTENDER_DUMMY_EFFECT = {
        id = 47460, name = "Protean prolonger",
        text = "Protean Prolonger - Doubles the maximum actions of any Protean production actions.",
    },
    COMBATV2_TRH_PROTEAN_POWERUP_DUMMY_EFFECT = {
        id = 6899, name = "Protean powerup",
        text = "Protean Powerup - Protean items can be used with increased speed.",
    },
    COMBATV2_TUSKAS_WRATH_COOLDOWN_DEBUFF = {
        id = 48291, name = "Tuska's Wrath CD",
        text = "The empowered effect of Tuska's Wrath is on cooldown.",
    },
    COMBATV2_VALENTINES_COIN_DUMMY_ABILITY = {
        id = 39803, name = "Valentine's Flip",
        text = "Valentine's Flip - 2% XP Boost",
    },
    COMBATV2_VALENTINES_STAFF_DUMMY_ABILITY = {
        id = 33047, name = "Valentine's Slam",
        text = "Valentine's Slam - 4% XP Boost",
    },
    COMBATV2_VENGEANCE = {
        id = 39026, name = "Vengeance",
        text = "The next time you receive damage, 75% of the damage received is also dealt to the attacker.",
    },
    COMBATV2_VENGEANCE_COOLDOWN = {
        id = 39029, name = "Vengeance CD",
        aliases = { "vengeance cooldown" },
        text = "Your Vengeance ability is on cooldown.",
    },
    COMBATV2_WHITE_FIRELIGHTER_BUFF = {
        id = 6957, name = "Fire spirit auto-catch",
        text = "Firelighter buff - you will automatically catch Fire Spirits.",
    },
    COMBATV2_WILDER_PIE_DUMMY_ABILITY = {
        id = 35781, name = "Wilder pie",
        text = "Wilder pie effect - Your slayer level has been boosted by 6 and will not drain while active.",
    },
    COMBATV2_WOODCUTTING_CONSUMABLE_ENCHANTED_NEST_CHANCE_DUMMY_ABILITY = {
        id = 29046, name = "Imbued bird feed",
        text = "Imbued bird feed - Increases your chance of finding enchanted birds nest by 10% while felling trees.",
    },
    COMBATV2_WOODCUTTING_CONSUMABLE_LOG_XP_DUMMY_ABILITY = {
        id = 29047, name = "Lumberjack's courage",
        text = "Lumberjack's courage - Increases XP from gaining a log by 20%.",
    },
    COMBATV2_WOODCUTTING_CONSUMABLE_NEST_ATTUNER_DUMMY_ABILITY = {
        id = 29048, name = "Bird whistle",
        text = "Bird whistle - Allows the user to obtain only a specific type of bird's nest.",
    },
    COMBATV2_WOODCUTTING_CONSUMABLE_PERFECT_CUT_CHANCE_DUMMY_ABILITY = {
        id = 29049, name = "Sharpening stone",
        text = "Sharpening stone - Increases perfect cut chance by +5%",
    },
    COMBATV2_YAKAMARU_DRENCH_DEBUFF = {
        id = 35802, name = "Drenched",
        text = "Drenched - Each stack increases damage taken from Yakamaru.",
    },
    DIVINATION_GOTE_PORTER_DISABLED = {
        id = 6850, name = "GotE porter disabled",
        text = "The porter functionality of your Grace of the Elves is disabled.",
    },
    DIVINATION_PORTER_ACTIVE = {
        id = 1624, name = "Sign of the porter",
        text = "Your sign of the porter is active, banking specific items, using a charge each time.",
    },
    ELFCITY_AMLODD_CAUGHT = {
        id = 35818, name = "Amlodd thieving CD",
        text = "The Amlodd clan has been warned about you, you'll have to wait before you can pickpocket them again.",
    },
    ELFCITY_CADARN_CAUGHT = {
        id = 35819, name = "Cadarn thieving CD",
        text = "The Cadarn clan has been warned about you, you'll have to wait before you can pickpocket them again.",
    },
    ELFCITY_CRWYS_CAUGHT = {
        id = 35820, name = "Crwys thieving CD",
        text = "The Crwys clan has been warned about you, you'll have to wait before you can pickpocket them again.",
    },
    ELFCITY_HEFIN_CAUGHT = {
        id = 35821, name = "Hefin thieving CD",
        text = "The Hefin clan has been warned about you, you'll have to wait before you can pickpocket them again.",
    },
    ELFCITY_IORWERTH_CAUGHT = {
        id = 35822, name = "Iorwerth thieving CD",
        text = "The Iorwerth clan has been warned about you, you'll have to wait before you can pickpocket them again.",
    },
    ELFCITY_ITHELL_CAUGHT = {
        id = 35823, name = "Ithell thieving CD",
        text = "The Ithell clan has been warned about you, you'll have to wait before you can pickpocket them again.",
    },
    ELFCITY_MEILYR_CAUGHT = {
        id = 35824, name = "Meilyr thieving CD",
        text = "The Meilyr clan has been warned about you, you'll have to wait before you can pickpocket them again.",
    },
    ELFCITY_TRAHAEARN_CAUGHT = {
        id = 35825, name = "Trahaearn thieving CD",
        text = "The Trahaearn clan has been warned about you, you'll have to wait before you can pickpocket them again.",
    },
    ELR2_CYCLOSIS_CAUGHT = {
        id = 35827, name = "Cyclosis thieving CD",
        text = "The Cyclosis islanders are alert to your thieving ways, you'll have to wait 5 minutes before you can pickpocket them again.",
    },
    ELR2_WAIKO_CAUGHT = {
        id = 35828, name = "Waiko thieving CD",
        text = "The Waiko islanders are alert to your thieving ways, you'll have to wait 5 minutes before you can pickpocket them again.",
    },
    FENMOOR_WOODCUTTING_BRAZIER_BUFF = {
        id = 4986, name = "Dry Heat",
        text = "Dry Heat - The nearby braziers are drying the tree, making it easier to work.",
    },
    FMC_REWARD_BOOK_ACTIVE = {
        id = 37421, name = "Book of Char",
        text = "Your Book of Char is active, burning any logs you walk over.",
    },
    HOUSE_RING_HIGH_COOLDOWN_DUMMY_ABILITY = {
        id = 44793, name = "Asylum ring CD",
        text = "Your Asylum surgeon's ring will not activate for at least 30 seconds.",
    },
    INVENT_CRYSTAL_SHIELD_COOLDOWN = {
        id = 1625, name = "Crystal Shield CD",
        text = "Your Crystal Shield effect will not activate for at least 60 seconds.",
    },
    INVENT_PERK_EQUILIBRIUM_COOLDOWN_DUMMY_ABILITY = {
        id = 14662, name = "Equilibrium CD",
        aliases = { "equilibrium cooldown", "equilibrium cd" },
        text = "Your Equilibrium perk is cooling down, you cannot critically strike.",
    },
    INVENT_PERK_RELENTLESS_COOLDOWN_DUMMY_ABILITY = {
        id = 44794, name = "Relentless CD",
        aliases = { "relentless cooldown", "relentless cd" },
        text = "Your Relentless perk will not activate for at least 30 seconds.",
    },
    INVENT_PERK_WISE = {
        id = 35826, name = "Wise",
        text = "Wise - Grants you extra experience per rank. When hitting 100% you'll no longer gain additional experience.",
    },
    MTX_PET_ABILITY_ALCHEMY = {
        id = 31331, name = "Pet alchemy CD",
        text = "Legendary Pet Ability: High Level Alchemy",
    },
    MTX_PET_ABILITY_BANKING = {
        id = 31326, name = "Pet banking CD",
        text = "Legendary Pet Ability: Banking",
    },
    MTX_PET_ABILITY_FERTILISER = {
        id = 31333, name = "Pet fertiliser CD",
        text = "Legendary Pet Ability: Fertiliser",
    },
    MTX_PET_ABILITY_LIFESAVER = {
        id = 31328, name = "Pet life saver CD",
        text = "Legendary Pet Ability: Life Saver",
    },
    MTX_PET_ABILITY_REPAIR = {
        id = 31330, name = "Pet repair CD",
        text = "Legendary Pet Ability: Item Repair",
    },
    SWORLDS_MUTATOR_CHARGED = {
        id = 1408, name = "Charged",
        text = "Deals damage to surrounding NPCs. Damage is increased with multiple stacks.",
    },
    SWORLDS_MUTATOR_FEELING_PUMPED = {
        id = 1400, name = "Unlimited adrenaline",
        text = "You currently have unlimited adrenaline",
    },
    SWORLDS_MUTATOR_STATIC = {
        id = 1392, name = "Static",
        text = "Static: Your damage taken is increased by the percentage shown. The longer you stand still the more this percentage increases.",
    },
    SWORLDS_OBJECTIVE_FOUNTAIN = {
        id = 1418, name = "Ghost hunt",
        text = "Kill as many ghosts as you can before the time expires",
    },
    SWORLDS_OBJECTIVE_RELIC_ANIMA_BOOST = {
        id = 1416, name = "Anima boost",
        text = "Anima Boost - You are gaining 50% more anima.",
    },
    SWORLDS_OBJECTIVE_RELIC_ANIMA_LIFEPOINTS = {
        id = 1417, name = "Anima healing",
        text = "Lifepoints Boost - All anima gained will instead heal you.",
    },
    TRH22_ATTUNEMENT_BAN_DUMMY_ABILITY = {
        id = 28786, name = "Wisdom attunement CD",
        text = "Residual totem attunement.You have residual totem attunement and you cannot attune yourself to a new totem until this fades.",
    },
    TRH22_LISTENER_DUMMY_ABILITY = {
        id = 28785, name = "Wisdom attunement",
        text = "Attuned to a totem of wisdom.You are attuned to a totem of wisdom and will gain bonus XP when the owner gains XP.",
    },
    TRH22_OWNER_DUMMY_ABILITY = {
        id = 28784, name = "Totem of wisdom",
        text = "Totem of wisdom.You currently own a totem of wisdom and will gain extra XP from it.",
    },
    TRH_SWEET_COOLDOWN_DUMMY_ABILITY = {
        id = 29170, name = "Chocolate CD",
        text = "Sweet toothYou have recently eaten a chocolate and can't have another one.",
    },
    TRH_SWEET_DAMAGE_DUMMY_ABILITY = {
        id = 29173, name = "Berserker's chocolate",
        text = "Berserker's chocolateYour attacks of all types currently do extra damage.",
    },
    TRH_SWEET_PORTER_DUMMY_ABILITY = {
        id = 29174, name = "Porter's chocolate",
        text = "Porter's chocolateYou will send some items you gather to the bank automatically.",
    },
    TRH_SWEET_REGENERATE_DUMMY_ABILITY = {
        id = 29171, name = "Healer's chocolate",
        text = "Healer's chocolateYou are currently regenerating health.",
    },
    TRH_SWEET_SHIELD_DUMMY_ABILITY = {
        id = 29172, name = "Knight's chocolate",
        text = "Knight's chocolateYou are currently shielded from some damage.",
    },
}
