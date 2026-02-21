Topic.destroy_all
Player.destroy_all
Court.destroy_all

Topic.create!(
  name: "Find a hitting partner near me",
  content: "I’m in Surry Hills and want a partner at my level this week. Help me filter and message people efficiently.",
  system_prompt: "Prioritize partner search filters, quick outreach templates, and scheduling options. Ask only the minimum clarifying questions needed."
)

Topic.create!(
  name: "Book a court without the drama",
  content: "I want a court after work (6–9pm). Help me shortlist nearby courts and plan backup options.",
  system_prompt: "Prioritize court shortlisting criteria, backup options, and timing decisions. Offer a simple decision checklist."
)

Topic.create!(
  name: "Message template: first meetup",
  content: "Write a friendly first message to a potential partner with time options, level, and a court suggestion.",
  system_prompt: "Prioritize drafting copy-paste message templates. Ask minimal clarifying questions and provide 2-3 tone variations."
)

Topic.create!(
  name: "Last-minute fill-in",
  content: "I have a court booking in 3 hours and my partner bailed. Help me find a replacement fast and what to say.",
  system_prompt: "Prioritize speed. Give short message templates and a rapid action checklist. Keep responses brief and immediately actionable."
)

Topic.create!(
  name: "Doubles group planning",
  content: "I need 4 players Sunday morning. Help me coordinate availability and propose a court.",
  system_prompt: "Prioritize coordination format, headcount confirmation, availability polling, and fallback plans if someone drops out."
)

# --- Mock inventory for Racket M8 demo ---
players = [
  { name: "Alex Tran",        suburb: "Marrickville", utr: 4.1, level_label: "Intermediate" },
  { name: "Samir Patel",      suburb: "Dulwich Hill", utr: 3.8, level_label: "Intermediate" },
  { name: "Jordan Lee",       suburb: "Newtown",      utr: 4.0, level_label: "Intermediate" },
  { name: "Chris Nguyen",     suburb: "Stanmore",     utr: 4.3, level_label: "Intermediate" },
  { name: "Ben Murphy",       suburb: "Enmore",       utr: 4.5, level_label: "Intermediate" },
  { name: "Arjun Rao",        suburb: "Petersham",    utr: 3.6, level_label: "Intermediate" },
  { name: "Daniel Kim",       suburb: "Camperdown",   utr: 4.2, level_label: "Intermediate" },
  { name: "Ethan Wilson",     suburb: "Ashfield",     utr: 3.9, level_label: "Intermediate" },
  { name: "Marcus Chen",      suburb: "Leichhardt",   utr: 4.4, level_label: "Intermediate" },
  { name: "Noah Haddad",      suburb: "Erskineville", utr: 3.7, level_label: "Intermediate" },
  { name: "Ryan Park",        suburb: "Tempe",        utr: 4.0, level_label: "Intermediate" },
  { name: "Luke Fernandes",   suburb: "Sydenham",     utr: 4.2, level_label: "Intermediate" },
  { name: "Mia Thompson",     suburb: "Marrickville", utr: 2.9, level_label: "Beginner" },
  { name: "Sophie Lim",       suburb: "Newtown",      utr: 3.2, level_label: "Beginner-Intermediate" },
  { name: "Priya Nair",       suburb: "Dulwich Hill", utr: 3.4, level_label: "Intermediate" },
  { name: "Hannah Brooks",    suburb: "Stanmore",     utr: 4.1, level_label: "Intermediate" },
  { name: "Emma Collins",     suburb: "Enmore",       utr: 4.6, level_label: "Advanced" },
  { name: "Zoe Martin",       suburb: "Petersham",    utr: 3.5, level_label: "Intermediate" }
]

players.each { |attrs| Player.create!(attrs) }

courts = [
  { name: "Marrickville Park Tennis Courts", suburb: "Marrickville", surface: "Hard",      lights: true  },
  { name: "Enmore Park Tennis Courts",       suburb: "Enmore",      surface: "Hard",      lights: true  },
  { name: "Petersham Park Tennis Courts",    suburb: "Petersham",   surface: "Hard",      lights: true  },
  { name: "Camperdown Park Tennis Courts",   suburb: "Camperdown",  surface: "Hard",      lights: true  },
  { name: "Sydney Park Courts",              suburb: "Alexandria",  surface: "Hard",      lights: false },
  { name: "Mason Park Tennis Courts",        suburb: "Homebush",    surface: "Hard",      lights: true  },
  { name: "Prince Alfred Park Courts",       suburb: "Surry Hills", surface: "Hard",      lights: true  },
  { name: "Moore Park Tennis",               suburb: "Moore Park",  surface: "Hard",      lights: true  },
  { name: "Ashfield Park Tennis Courts",     suburb: "Ashfield",    surface: "Hard",      lights: true  },
  { name: "Leichhardt Park Tennis Courts",   suburb: "Leichhardt",  surface: "Hard",      lights: true  }
]

courts.each { |attrs| Court.create!(attrs) }

puts "Seeded #{Topic.count} topics"
puts "Seeded #{Player.count} players"
puts "Seeded #{Court.count} courts"
