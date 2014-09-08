# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    first_name "MyString"
    last_name "MyString"
    gender "MyString"
    date_of_birth "2014-09-08"
    user_name "MyString"
    sequence(:email){|n| "user#{n}@factory.com" }
    password '123456789'
    password_confirmation '123456789'
  end
end
