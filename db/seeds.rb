# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

User.delete_all
puts "Populating database by users..."
10.times do
  FactoryGirl.create :user,
                     latitude:  rand(48.623..48.63),
                     longitude: rand(22.297..22.3)
end
puts "User's locations:"
p User.all.map(&:address)
