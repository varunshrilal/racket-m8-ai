# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
Topic.destroy_all

Topic.create!(
  name: "Find a hitting partner near me",
  content: "I’m in Surry Hills and want a partner at my level this week. Help me filter and message people efficiently."
)

Topic.create!(
  name: "Book a court without the drama",
  content: "I want a court after work (6–9pm). Help me shortlist nearby courts and plan backup options."
)

Topic.create!(
  name: "Message template: first meetup",
  content: "Write a friendly first message to a potential partner with time options, level, and a court suggestion."
)

Topic.create!(
  name: "Last-minute fill-in",
  content: "I have a court booking in 3 hours and my partner bailed. Help me find a replacement fast and what to say."
)

Topic.create!(
  name: "Doubles group planning",
  content: "I need 4 players Sunday morning. Help me coordinate availability and propose a court."
)

