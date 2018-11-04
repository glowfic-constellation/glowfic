Template.create!([
  { user_id: 1, name: "Alli" },
  { user_id: 1, name: "Emma" },
  { user_id: 2, name: "Bell" },
  { user_id: 3, name: "Sherlock" },
  { user_id: 1, name: "Jenny" },
  { user_id: 3, name: "Joker" },
  { user_id: 1, name: "Vivian" },
  { user_id: 2, name: "Alex" },
  { user_id: 2, name: "Olympian" },
  { user_id: 3, name: "Mark" },
  { user_id: 3, name: "Miles" },
  { user_id: 2, name: "Elspeth" },
])

puts "Creating characters..."
Character.create!([
  {
    user_id: 1,
    name: "Cass Cutler",
    screenname: "undercover_talent",
    default_icon_id: 13,
    pb: "Michelle Rodriguez"
  },
  {
    user_id: 1,
    name: "Alli Kowalski",
    screenname: "witch_perfect",
    template_id: 1,
    default_icon_id: 6,
    pb: "Alexandra Daddario"
  },
  {
    user_id: 1,
    name: "Alli Kowalski",
    screenname: "witch_please",
    template_id: 1,
    default_icon_id: 102,
    pb: "Alexandra Daddario"
  },
  {
    user_id: 1,
    name: "Emma Miller Anderson",
    template_name: "Anderson",
    screenname: "ipsam_custodem",
    template_id: 2,
    default_icon_id: 8,
    pb: "Shailene Woodley"
  },
  {
    user_id: 1,
    name: "Emma Mason",
    template_name: "Mason",
    screenname: "parental_guidance",
    template_id: 2,
    default_icon_id: 7,
    pb: "Shailene Woodley"
  },
  {
    user_id: 1,
    name: "Genevieve O'Meara",
    template_name: "O'Meara",
    screenname: "metamorphmaga",
    template_id: 5,
    default_icon_id: 11,
    pb: "Christina Aguilera"
  },
  {
    user_id: 1,
    name: "Jenny Marino",
    template_name: "Jenny",
    screenname: "bright_and_beautiful",
    template_id: 5,
    default_icon_id: 10,
    pb: "Christina Aguilera"
  },
  {
    user_id: 1,
    name: "Eleanor Miller",
    pb: "Diane Lane"
  },
  {
    user_id: 1,
    name: "William Miller",
    screenname: "hidebound",
    default_icon_id: 12,
    pb: "George Newbern"
  },
  {
    user_id: 2,
    name: "Elspeth Annarose Cullen",
    template_name: "Elspeth",
    screenname: "her_imperial_radiance",
    template_id: 12,
    default_icon_id: 18,
    pb: "Astrid Bergès-Frisbey"
  },
  {
    user_id: 3,
    name: "Sherlock Holmes",
    screenname: "calendarofcrime",
    template_id: 4,
    default_icon_id: 58,
    pb: "Hayley Atwell"
  },
  {
    user_id: 2,
    name: "Holly / Crystal",
    screenname: "inourhead",
    default_icon_id: 19,
    pb: "Aisha Dee"
  },
  {
    user_id: 2,
    name: "Jane",
    screenname: "mind_game",
    default_icon_id: 32
  },
  {
    user_id: 2,
    name: "Aleko Fylt Swan Ardelay | \"Ko\"",
    template_name: "Aleko",
    screenname: "liakoura",
    template_id: 8,
    default_icon_id: 28,
    pb: "Dylan O'Brien"
  },
  {
    user_id: 2,
    name: "Alexandra Phyllis Swan | \"Lexi\"",
    template_name: "Lexi",
    screenname: "lexicality",
    template_id: 8,
    default_icon_id: 26,
    pb: "Christie Burke"
  },
  {
    user_id: 2,
    name: "Alexandra Phyllis Swan | \"Andi\"",
    template_name: "Andi",
    screenname: "pandion",
    template_id: 8,
    default_icon_id: 39,
    pb: "Christie Burke"
  },
  {
    user_id: 2,
    name: "Zeus Bartholomew Norton",
    screenname: "floofcoaster",
    template_id: 9,
    default_icon_id: 16
  },
  {
    user_id: 2,
    name: "Patience Frothen",
    screenname: "salt_of_the",
    template_id: 9,
    default_icon_id: 40
  },
  {
    user_id: 3,
    name: "Alice",
    screenname: "edgeofyourseat",
    template_id: 6,
    default_icon_id: 65,
    pb: "Heath Ledger"
  },
  {
    user_id: 3,
    name: "Sherlock Holmes",
    screenname: "bitofafiction",
    template_id: 4,
    default_icon_id: 48,
    pb: "Robert Downey Jr"
  },
  {
    user_id: 3,
    name: "Solvei Koskin",
    template_name: "Solvei",
    screenname: "gloriousdawn",
    template_id: 11,
    default_icon_id: 67,
    pb: "Rosario Dawson"
  },
  {
    user_id: 3,
    name: "Jarvis",
    screenname: "poeticterms"
  },
  {
    user_id: 3,
    name: "Pyth",
    screenname: "pythbox",
    default_icon_id: 3
  },
  {
    user_id: 3,
    name: "Sigyn",
    template_name: "Sigyn",
    screenname: "thevictorious",
    template_id: 10,
    default_icon_id: 86,
    pb: "Willy Cartier"
  },
  {
    user_id: 1,
    name: "Alianora of Toure-on-Marsh",
    template_name: "Alianora",
    screenname: "raging_firewitch",
    template_id: 1,
    default_icon_id: 100,
    pb: "Darby Stanchfield"
  },
  {
    user_id: 3,
    name: "Mark Pierre Vorkosigan",
    template_name: "Mark",
    screenname: "unmarred",
    template_id: 10,
    default_icon_id: 91,
    pb: "Sebastian Stan"
  },
  {
    user_id: 3,
    name: "Miles Naismith Vorkosigan",
    template_name: "Miles",
    screenname: "thisvorlunatic",
    template_id: 11,
    default_icon_id: 89,
    pb: "Sebastian Stan"
  },
  {
    user_id: 2,
    name: "Linyabel Miriat ⍟ \"Linya\"",
    template_name: "Linya",
    screenname: "isthisart",
    template_id: 3,
    default_icon_id: 21,
    pb: "Kristen Stewart"
  },
  {
    user_id: 2,
    name: "Isabella Marie Swan Ø \"Pattern\"",
    template_name: "Pattern",
    screenname: "bellfounding",
    template_id: 3,
    default_icon_id: 14,
    pb: "Kristen Stewart"
  },
  {
    user_id: 2,
    name: "Isabella Marie Swan Cullen ☼ \"Golden\"",
    template_name: "Golden",
    screenname: "luminous_regnant",
    template_id: 3,
    default_icon_id: 30,
    pb: "Kristen Stewart"
  },
  {
    user_id: 2,
    name: "Isabella Marie Swan ✴ \"Stella\"",
    template_name: "Stella",
    screenname: "self_composed",
    template_id: 3,
    default_icon_id: 42,
    pb: "Kristen Stewart"
  },
  {
    user_id: 2,
    name: "Isabella Mariel Swan ∀ \"Glass\"",
    template_name: "Glass",
    screenname: "thaumobabble",
    template_id: 3,
    default_icon_id: 47,
    pb: "Kristen Stewart"
  },
  {
    user_id: 3,
    name: "Jokes",
    screenname: "manofmyword",
    template_id: 6,
    default_icon_id: 72,
    pb: "Heath Ledger"
  },
])

puts "Creating character aliases..."
CharacterAlias.create!([
  {
    character_id: 6,
    name: "Jenny O'Meara"
  },
  {
    character_id: 19,
    name: "Laney"
  },
  {
    character_id: 19,
    name: "Whistle"
  },
])
