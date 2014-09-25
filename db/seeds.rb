User.destroy_all
puts "Populating database by users..."
10.times do
  FactoryGirl.create :user_confirmed,
                     latitude:  rand(48.623..48.63),
                     longitude: rand(22.297..22.3)
end
