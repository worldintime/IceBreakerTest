User.destroy_all
CannedStatement.destroy_all

puts 'Creating 200 test users...'

200.times do |t|
  User.create(first_name: "Test#{t}", last_name: "Test#{t}", email: "Test#{t}@gmail.com", user_name: "Test#{t}",
              gender: 'male', password: '123456789', password_confirmation: '123456789', confirmation_token: nil,
              confirmed_at: DateTime.now)
end

puts "Populating database by users..."
10.times do
  FactoryGirl.create :user_confirmed,
                     latitude:  rand(48.623..48.63),
                     longitude: rand(22.297..22.3)
  FactoryGirl.create :canned_statement
end
