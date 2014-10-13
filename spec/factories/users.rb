# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    sequence(:first_name){|n| "Tom_#{n}"}
    sequence(:last_name){|n| "Hasher_#{n}"}
    gender "male"
    date_of_birth "2014-09-08"
    user_name {|u| u.first_name.downcase}
    email{|u| "#{u.first_name.downcase}@factory.com"}
    password '123456789'
    password_confirmation '123456789'
    facebook_rating 0

    factory :user_confirmed do
      confirmation_token nil
      confirmed_at Time.now
    end
  end
end
