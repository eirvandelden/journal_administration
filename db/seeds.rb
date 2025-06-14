# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup].
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }]]
#   Character.create(name: 'Luke', movie: movies.first]

## Users
User.create(name: "Etienne van Delden de la Haije", email_address: "etienne@vandelden.family",
password: "testtest1", role: :administrator) unless User.find_by(email_address: "etienne@vandelden.family").present?

## Categories
[
  "Inkomsten",
  "Inkomsten - Salaris",
  "Inkomsten - Bonus / 13e maand",
  "Inkomsten - Vakantiegeld",
  "Inkomsten - Giften",
  "Inkomsten - Belastingdienst teruggaaf",
  "Inkomsten - Kinderbijslag",
  "Inkomsten - Reiskostenvergoeding"
].each do |name|
  Category.find_or_create_by name: name, direction: :debit
end

[
  "Vaste lasten",
  "Vaste lasten - Hypotheek",
  "Vaste lasten - Huur",
  "Vaste lasten - Servicekosten",
  "Vaste lasten - Water",
  "Vaste lasten - Energie",
  "Vaste lasten - Brabant Water"
].each do |name|
  Category.find_or_create_by name: name, direction: :credit
end

[
  "Heffingen",
  "Heffingen - Onroerend zaakbelasting",
  "Heffingen - Waterschap",
  "Heffingen - Riool",
  "Heffingen - Afval"
].each do |name|
  Category.find_or_create_by name: name, direction: :credit
end

[
  "Abonnementen",
  "Abonnementen - Mobiele Internet en telefonie",
  "Abonnementen - Vaste Internet, telefonie en tv",
  "Abonnementen - Video",
  "Abonnementen - Muziek",
  "Abonnementen - Sport",
  "Abonnementen - Lezen"
].each do |name|
  Category.find_or_create_by name: name, direction: :credit
end

[
  "Verzekeringen",
  "Verzekeringen - Zorg",
  "Verzekeringen - Privepakket",
  "Verzekeringen - Uitvaartverzekering"
].each do |name|
  Category.find_or_create_by name: name, direction: :credit
end

[
  "Auto en vervoer",
  "Auto en vervoer - Tanken",
  "Auto en vervoer - Parkeren",
  "Auto en vervoer - Onderhoud"
].each do |name|
  Category.find_or_create_by name: name, direction: :credit
end

[
  "Huishoudelijke uitgaven",
  "Huishoudelijke uitgaven - Boodschappen",
  "Huishoudelijke uitgaven - Huishoudelijk",
  "Huishoudelijke uitgaven - Verzorging",
  "Huishoudelijke uitgaven - Kapper",
  "Huishoudelijke uitgaven - Tandarts"
].each do |name|
  Category.find_or_create_by name: name, direction: :credit
end

[
  "Schulden",
  "Schulden - Studieschuld",
  "Schulden - Creditcard",
  "Schulden - Geleend"
].each do |name|
  Category.find_or_create_by name: name, direction: :credit
end

[
  "Ontspanning",
  "Ontspanning - Uitjes",
  "Ontspanning - Pretpark",
  "Ontspanning - Dierentuin",
  "Ontspanning - Musea",
  "Ontspanning - Tussendoortje",
  "Ontspanning - Lunch",
  "Ontspanning - Uit eten",
  "Ontspanning - Speelgoed",
  "Ontspanning - Hobby",
  "Ontspanning - Lectuur"
].each do |name|
  Category.find_or_create_by name: name, direction: :credit
end

[
  "Kleding",
  "Kleding - Etienne",
  "Kleding - Michèlle",
  "Kleding - Serena",
  "Kleding - Cosimo",
  "Kleding - Chiara"
].each do |name|
  Category.find_or_create_by name: name, direction: :credit
end

[
  "Vakantie",
  "Vakantie - Verblijf",
  "Vakantie - Vervoer",
  "Vakantie - Eten en drinken"
].each do |name|
  Category.find_or_create_by name: name, direction: :credit
end

[
  "Huis",
  "Huis - Meubels",
  "Huis - Inrichting",
  "Huis - Tuin",
  "Huis - Klussen"
].each do |name|
  Category.find_or_create_by name: name, direction: :credit
end

[
  "Overige uitgaven",
  "Overige uitgaven - Cadeautjes",
  "Overige Uitgaven -"
].each do |name|
  Category.find_or_create_by name: name, direction: :credit
end

[
  "Technisch",
  "Technisch - Domein",
  "Technisch - Online opslag"
].each do |name|
  Category.find_or_create_by name: name, direction: :credit
end

[ "Transfer" ].each { |name| Category.find_or_create_by name: name, direction: :debit }

## Accounts
