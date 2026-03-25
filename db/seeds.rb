romebots_cards = [
  {
    key: "caesars_will",
    title: "Caesar's Will",
    body: "Caesar speaks from the document and the grave at once: son, heir, name-bearer. The Julian household wants you crowned in memory before Antony can turn the city into his inheritance.",
    card_type: "authored",
    speaker_type: "figure",
    speaker_key: "caesar",
    speaker_name: "Julius Caesar",
    portrait_key: "caesar",
    faction_key: "julian_house",
    weight: 100,
    tags: %w[opening politics legitimacy family],
    spawn_rules: { min_year: -44, max_year: -44, required_flags: ["flags.caesar_assassinated"], one_time_only: true },
    response_a_text: "Claim Caesar's name before Antony swallows it.",
    response_a_effects: [
      { op: "increment", key: "state.legitimacy", value: 10 },
      { op: "increment", key: "state.public_order", value: -2 },
      { op: "increment", key: "relations.antony", value: -1 },
      { op: "increment", key: "factions.julian_house", value: 2 }
    ],
    response_a_states: [
      { action: "add", key: "mourning_period", duration: { until_year_end: true } }
    ],
    response_b_text: "Accept the inheritance, but unveil it cautiously.",
    response_b_effects: [
      { op: "increment", key: "state.legitimacy", value: 5 },
      { op: "increment", key: "state.senate_support", value: 2 },
      { op: "increment", key: "state.public_order", value: 1 },
      { op: "increment", key: "factions.julian_house", value: 1 },
      { op: "increment", key: "factions.senate_bloc", value: 1 }
    ],
    response_b_states: [
      { action: "add", key: "mourning_period", duration: { turns: 2 } }
    ]
  },
  {
    key: "return_to_rome",
    title: "Return to Rome",
    body: "Agrippa's message is blunt: your friends in Campania can raise support, but every day you stay away lets Antony own the Forum and the story. Your circle wants movement; your cautious advisers want survival.",
    card_type: "authored",
    speaker_type: "figure",
    speaker_key: "agrippa",
    speaker_name: "Agrippa",
    portrait_key: "agrippa",
    faction_key: "octavian_circle",
    weight: 95,
    tags: %w[opening politics mobility],
    spawn_rules: { min_year: -44, max_year: -44, one_time_only: true, required_flags: ["flags.caesar_adopted_heir"] },
    response_a_text: "Ride for Rome and force yourself into the quarrel.",
    response_a_effects: [
      { op: "set", key: "flags.returned_to_rome", value: true },
      { op: "increment", key: "state.legitimacy", value: 6 },
      { op: "increment", key: "state.military_support", value: 2 },
      { op: "increment", key: "relations.agrippa", value: 1 },
      { op: "increment", key: "factions.octavian_circle", value: 2 }
    ],
    response_b_text: "Build your camp first, then enter the city on your terms.",
    response_b_effects: [
      { op: "increment", key: "state.senate_support", value: 3 },
      { op: "increment", key: "state.legitimacy", value: 2 },
      { op: "increment", key: "state.public_order", value: 1 },
      { op: "increment", key: "relations.agrippa", value: -1 },
      { op: "increment", key: "factions.senate_bloc", value: 1 }
    ]
  },
  {
    key: "the_comet",
    title: "The Comet",
    body: "At the games, a comet burns above Rome and the priests start whispering before the crowd does. Your propagandists smell a dynasty; the old nobles smell blasphemy dressed as theater.",
    card_type: "authored",
    speaker_type: "group",
    speaker_key: "festival_priests",
    speaker_name: "Priests Of The Games",
    portrait_key: "festival_priests",
    faction_key: "roman_priesthood",
    weight: 85,
    tags: %w[propaganda omen legitimacy public],
    spawn_rules: { min_year: -44, max_year: -43, one_time_only: true },
    response_a_text: "Name it Caesar's soul and let Rome repeat it.",
    response_a_effects: [
      { op: "increment", key: "state.legitimacy", value: 8 },
      { op: "increment", key: "state.public_order", value: 2 },
      { op: "increment", key: "state.senate_support", value: -2 }
    ],
    response_b_text: "Stay solemn and let the omen work without your voice on it.",
    response_b_effects: [
      { op: "increment", key: "state.legitimacy", value: 3 },
      { op: "increment", key: "state.senate_support", value: 1 }
    ]
  },
  {
    key: "ciceros_offer",
    title: "Cicero's Offer",
    body: "Cicero arrives with polished outrage and the Senate at his back. He wants Antony cut down in speeches first and, if needed, by your ambition second. He offers legitimacy, not loyalty.",
    card_type: "authored",
    speaker_type: "figure",
    speaker_key: "cicero",
    speaker_name: "Cicero",
    portrait_key: "cicero",
    faction_key: "senate_bloc",
    weight: 84,
    tags: %w[senate alliance cicero politics],
    spawn_rules: { min_year: -44, max_year: -43, one_time_only: true },
    response_a_text: "Take Cicero's hand and borrow the Senate's voice.",
    response_a_effects: [
      { op: "set", key: "flags.met_cicero", value: true },
      { op: "increment", key: "relations.cicero", value: 2 },
      { op: "increment", key: "state.senate_support", value: 5 },
      { op: "increment", key: "relations.antony", value: -2 },
      { op: "increment", key: "factions.senate_bloc", value: 2 }
    ],
    response_a_follow_up_card_key: "antonys_terms",
    response_b_text: "Accept his praise, but never become his instrument.",
    response_b_effects: [
      { op: "set", key: "flags.met_cicero", value: true },
      { op: "increment", key: "relations.cicero", value: 1 },
      { op: "increment", key: "state.senate_support", value: 2 },
      { op: "increment", key: "state.legitimacy", value: 1 },
      { op: "increment", key: "factions.senate_bloc", value: 1 }
    ]
  },
  {
    key: "antonys_terms",
    title: "Antony's Terms",
    body: "Antony sends terms through hard men with easy smiles. His faction would prefer a tame heir under their shadow to a rival with Caesar's blood in his mouth. Peace is on offer, provided you understand who is meant to bow.",
    card_type: "authored",
    speaker_type: "figure",
    speaker_key: "antony",
    speaker_name: "Mark Antony",
    portrait_key: "antony",
    faction_key: "antonian_faction",
    weight: 83,
    tags: %w[antony rival politics power],
    spawn_rules: { min_year: -44, max_year: -43, one_time_only: true },
    response_a_text: "Take the peace and buy yourself time.",
    response_a_effects: [
      { op: "increment", key: "relations.antony", value: 2 },
      { op: "increment", key: "state.public_order", value: 1 },
      { op: "increment", key: "state.legitimacy", value: -1 },
      { op: "increment", key: "factions.antonian_faction", value: 2 }
    ],
    response_b_text: "Refuse and make the break public.",
    response_b_effects: [
      { op: "set", key: "flags.antony_open_enemy", value: true },
      { op: "increment", key: "relations.antony", value: -3 },
      { op: "increment", key: "state.legitimacy", value: 4 },
      { op: "increment", key: "state.military_support", value: 1 },
      { op: "increment", key: "factions.antonian_faction", value: -2 }
    ],
    response_b_states: [
      { action: "add", key: "eastern_intrigue", duration: { turns: 2 } }
    ],
    response_b_follow_up_card_key: "a_narrow_escape"
  },
  {
    key: "veterans_want_payment",
    title: "Veterans Want Payment",
    body: "Caesar's veterans do not care for constitutional theory. Their officers ask, very politely, whether the heir of Caesar intends to honor Caesar's promises or merely inherit his compliments.",
    card_type: "authored",
    speaker_type: "group",
    speaker_key: "caesarian_veterans",
    speaker_name: "Caesars Veterans",
    portrait_key: "caesarian_veterans",
    faction_key: "legions",
    weight: 80,
    tags: %w[military veterans treasury loyalty],
    spawn_rules: { min_year: -44, max_year: -42 },
    response_a_text: "Pay them now. Legions remember silver better than speeches.",
    response_a_effects: [
      { op: "increment", key: "state.treasury", value: -10 },
      { op: "increment", key: "state.military_support", value: 6 },
      { op: "increment", key: "state.legitimacy", value: 2 },
      { op: "increment", key: "relations.legions", value: 2 },
      { op: "increment", key: "factions.legions", value: 2 }
    ],
    response_b_text: "Stall, bargain, and promise future reward.",
    response_b_effects: [
      { op: "increment", key: "state.treasury", value: -2 },
      { op: "increment", key: "state.military_support", value: -2 },
      { op: "increment", key: "state.public_order", value: -1 },
      { op: "increment", key: "relations.legions", value: -2 },
      { op: "increment", key: "factions.legions", value: -2 }
    ],
    response_b_states: [
      { action: "add", key: "veteran_discontent", duration: { turns: 2 } }
    ]
  },
  {
    key: "grain_anxiety",
    title: "Grain Anxiety",
    body: "Cicero arrives with fresh panic and fresher numbers: grain queues are thickening, tempers are shortening, and Antony's faction would love a hungry city looking for someone to curse. He presents the bread crisis as public policy and private opportunity at once.",
    card_type: "authored",
    speaker_type: "figure",
    speaker_key: "cicero",
    speaker_name: "Cicero",
    portrait_key: "cicero",
    faction_key: "senate_bloc",
    weight: 75,
    tags: %w[public grain order urban],
    spawn_rules: { min_year: -44, max_year: -30 },
    response_a_text: "Spend freely and deny Antony a starving audience.",
    response_a_effects: [
      { op: "increment", key: "state.treasury", value: -6 },
      { op: "increment", key: "state.public_order", value: 5 },
      { op: "increment", key: "relations.cicero", value: 1 },
      { op: "increment", key: "relations.plebs", value: 1 },
      { op: "increment", key: "factions.senate_bloc", value: 1 }
    ],
    response_a_states: [
      { action: "remove", key: "grain_crisis" }
    ],
    response_b_text: "Blame hoarders, save the treasury, and risk the crowd's mood.",
    response_b_effects: [
      { op: "increment", key: "state.public_order", value: 1 },
      { op: "increment", key: "state.legitimacy", value: -1 },
      { op: "increment", key: "relations.cicero", value: -1 },
      { op: "increment", key: "relations.plebs", value: -1 },
      { op: "increment", key: "factions.antonian_faction", value: 1 }
    ],
    response_b_states: [
      { action: "add", key: "grain_crisis", duration: { until_year_end: true } },
      { action: "add", key: "whisper_campaign", duration: { until_year_end: true } }
    ],
    response_b_follow_up_card_key: "whisper_campaign"
  },
  {
    key: "marriage_proposal",
    title: "Marriage Proposal",
    body: "A senatorial house offers marriage with careful warmth and obvious arithmetic. Their faction wants access to your future before it becomes the state's future. Your friends call it useful; you call it a leash with good tailoring.",
    card_type: "authored",
    speaker_type: "group",
    speaker_key: "allied_house",
    speaker_name: "An Allied House",
    portrait_key: "allied_house",
    faction_key: "senatorial_families",
    weight: 70,
    tags: %w[family marriage alliance dynasty],
    spawn_rules: { min_year: -44, max_year: -35, excluded_flags: ["flags.married"], one_time_only: true },
    response_a_text: "Accept. Let the alliance wear a wedding veil.",
    response_a_effects: [
      { op: "set", key: "flags.married", value: true },
      { op: "increment", key: "state.legitimacy", value: 3 },
      { op: "increment", key: "state.senate_support", value: 2 },
      { op: "increment", key: "state.heir_pressure", value: -2 },
      { op: "increment", key: "factions.senatorial_families", value: 2 }
    ],
    response_b_text: "Decline politely and keep your dynasty unpromised.",
    response_b_effects: [
      { op: "increment", key: "state.legitimacy", value: -1 },
      { op: "increment", key: "state.heir_pressure", value: 4 },
      { op: "increment", key: "factions.senatorial_families", value: -1 }
    ]
  },
  {
    key: "whisper_campaign",
    title: "Whisper Campaign",
    body: "By noon, Antony's friends in the taverns have improved your reputation into a string of insults: soft, reckless, sickly, un-Roman, and somehow all at once. The stories travel through Rome with suspicious discipline for something that is supposedly spontaneous.",
    card_type: "authored",
    speaker_type: "figure",
    speaker_key: "antony",
    speaker_name: "Mark Antony",
    portrait_key: "antony",
    faction_key: "antonian_faction",
    weight: 60,
    tags: %w[propaganda public rivals recurring],
    spawn_rules: { min_year: -44, max_year: 14, repeatable: true },
    response_a_text: "Answer Antony's lies in public and humiliate them by name.",
    response_a_effects: [
      { op: "increment", key: "state.legitimacy", value: 2 },
      { op: "increment", key: "state.treasury", value: -2 },
      { op: "increment", key: "relations.antony", value: -1 },
      { op: "increment", key: "factions.antonian_faction", value: -1 }
    ],
    response_a_states: [
      { action: "remove", key: "whisper_campaign" }
    ],
    response_b_text: "Trace the whisper network quietly and punish its paymasters.",
    response_b_effects: [
      { op: "increment", key: "state.public_order", value: 1 },
      { op: "increment", key: "relations.plebs", value: -1 },
      { op: "increment", key: "relations.antony", value: -1 },
      { op: "increment", key: "factions.antonian_faction", value: -2 }
    ],
    response_b_states: [
      { action: "remove", key: "whisper_campaign" }
    ]
  },
  {
    key: "omen_at_dawn",
    title: "Omen at Dawn",
    body: "Before sunrise, Rome produces a fresh omen and an even fresher priestly interpretation. The temples would like patronage, the people would like reassurance, and the practical men around you would like everyone to stop talking about birds.",
    card_type: "system",
    speaker_type: "group",
    speaker_key: "omens_of_rome",
    speaker_name: "Omens Of Rome",
    portrait_key: "omens_of_rome",
    faction_key: "roman_priesthood",
    weight: 40,
    tags: %w[fallback omen public],
    spawn_rules: { min_year: -44, max_year: 14, repeatable: true },
    response_a_text: "Fund the rites and let the city see your piety.",
    response_a_effects: [
      { op: "increment", key: "state.treasury", value: -2 },
      { op: "increment", key: "state.public_order", value: 2 },
      { op: "increment", key: "state.legitimacy", value: 1 },
      { op: "increment", key: "factions.roman_priesthood", value: 1 }
    ],
    response_b_text: "Dismiss the omen and keep the state on business.",
    response_b_effects: [
      { op: "increment", key: "state.senate_support", value: 1 },
      { op: "increment", key: "state.public_order", value: -1 },
      { op: "increment", key: "factions.roman_priesthood", value: -1 }
    ]
  },
  {
    key: "a_loyal_friend",
    title: "A Loyal Friend",
    body: "Agrippa asks for something better than affection: an actual command, visible responsibility, and the right to solve problems before older Romans explain why a young man should not. Your own circle needs teeth if it is going to survive the year.",
    card_type: "system",
    speaker_type: "figure",
    speaker_key: "agrippa",
    speaker_name: "Agrippa",
    portrait_key: "agrippa",
    faction_key: "octavian_circle",
    weight: 35,
    tags: %w[fallback ally administration military],
    spawn_rules: { min_year: -44, max_year: 14, repeatable: true },
    response_a_text: "Give Agrippa the command and let competence become loyalty.",
    response_a_effects: [
      { op: "increment", key: "state.military_support", value: 2 },
      { op: "increment", key: "relations.agrippa", value: 1 },
      { op: "increment", key: "factions.octavian_circle", value: 2 }
    ],
    response_b_text: "Keep Agrippa close, trusted, and publicly untested.",
    response_b_effects: [
      { op: "increment", key: "state.senate_support", value: 1 },
      { op: "increment", key: "state.public_order", value: 1 },
      { op: "increment", key: "relations.agrippa", value: -1 },
      { op: "increment", key: "factions.octavian_circle", value: -1 }
    ]
  },
  {
    key: "a_narrow_escape",
    title: "A Narrow Escape",
    body: "A shove in the crowd, a frightened horse, a knife glimpsed too late, and Agrippa is suddenly shouting men into position around you. Your supporters blame Antony's friends; Antony's friends blame excitement. Either way, Rome has learned that your rise comes with reachable flesh.",
    card_type: "system",
    speaker_type: "figure",
    speaker_key: "agrippa",
    speaker_name: "Agrippa",
    portrait_key: "agrippa",
    faction_key: "octavian_circle",
    weight: 30,
    tags: %w[fallback danger public],
    spawn_rules: { min_year: -44, max_year: 14, repeatable: true },
    response_a_text: "Let Agrippa harden the guard and make security visible.",
    response_a_effects: [
      { op: "increment", key: "state.treasury", value: -3 },
      { op: "increment", key: "state.public_order", value: 1 },
      { op: "increment", key: "state.legitimacy", value: -1 },
      { op: "increment", key: "relations.agrippa", value: 1 },
      { op: "increment", key: "factions.octavian_circle", value: 1 }
    ],
    response_a_states: [
      { action: "add", key: "guard_mobilized", duration: { turns: 3 } }
    ],
    response_b_text: "Wave Agrippa off and refuse to look hunted.",
    response_b_effects: [
      { op: "increment", key: "state.public_order", value: -2 },
      { op: "increment", key: "state.legitimacy", value: 1 },
      { op: "increment", key: "relations.agrippa", value: -1 },
      { op: "increment", key: "factions.antonian_faction", value: 1 }
    ]
  },
  {
    key: "letters_from_the_east",
    title: "Letters From The East",
    body: "Merchants, exiles, and ambitious princes all write at once. The eastern courts are not yet at war for your name, but they are already testing whether Rome's young claimant can be pulled into their bargains.",
    card_type: "system",
    speaker_type: "group",
    speaker_key: "eastern_envoys",
    speaker_name: "Eastern Envoys",
    portrait_key: "eastern_envoys",
    faction_key: "senatorial_families",
    weight: 28,
    tags: %w[east intrigue diplomacy trade],
    spawn_rules: {
      min_year: -43,
      max_year: 14,
      repeatable: true,
      required_context: [
        { key: "flags.returned_to_rome", equals: true }
      ]
    },
    response_a_text: "Open the correspondence and keep eastern options alive.",
    response_a_effects: [
      { op: "increment", key: "state.senate_support", value: -1 },
      { op: "increment", key: "state.legitimacy", value: 1 },
      { op: "increment", key: "factions.octavian_circle", value: 1 }
    ],
    response_a_states: [
      { action: "add", key: "eastern_intrigue", duration: { turns: 2 } }
    ],
    response_b_text: "File the letters away and keep Rome at the center of your attention.",
    response_b_effects: [
      { op: "increment", key: "state.public_order", value: 1 },
      { op: "increment", key: "factions.senate_bloc", value: 1 }
    ]
  },
  {
    key: "eastern_petition",
    title: "Eastern Petition",
    body: "An embassy from the eastern client courts asks for arbitration, money, and the favor of a man they are not yet sure will matter next year. Their rivals are listening for every Roman hesitation.",
    card_type: "system",
    speaker_type: "group",
    speaker_key: "eastern_envoys",
    speaker_name: "Eastern Envoys",
    portrait_key: "eastern_envoys",
    faction_key: "senatorial_families",
    weight: 26,
    tags: %w[east intrigue court diplomacy],
    spawn_rules: {
      min_year: -43,
      max_year: 14,
      repeatable: true,
      required_context: [
        { key: "flags.returned_to_rome", equals: true }
      ],
      required_session_states: ["eastern_intrigue"]
    },
    response_a_text: "Intervene carefully and make the eastern courts remember your favor.",
    response_a_effects: [
      { op: "increment", key: "state.treasury", value: -3 },
      { op: "increment", key: "state.legitimacy", value: 2 },
      { op: "increment", key: "factions.octavian_circle", value: 1 }
    ],
    response_b_text: "Refuse the petition and let the eastern theater cool.",
    response_b_effects: [
      { op: "increment", key: "state.treasury", value: 1 },
      { op: "increment", key: "state.senate_support", value: 1 }
    ],
    response_b_states: [
      { action: "remove", key: "eastern_intrigue" }
    ]
  }
]

romebots_cards.each do |attributes|
  CardDefinition.upsert(
    attributes.reverse_merge(response_a_states: [], response_b_states: []).merge(
      active: true,
      scenario_key: "romebots",
      updated_at: Time.current,
      created_at: Time.current
    ),
    unique_by: [:scenario_key, :key]
  )
end
