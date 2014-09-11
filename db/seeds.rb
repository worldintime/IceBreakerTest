# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

User.delete_all
10.times do
  FactoryGirl.create :user,
                     latitude: rand(40.0000..50.0000),
                     longitude: rand(20.0000..30.0000)
end
