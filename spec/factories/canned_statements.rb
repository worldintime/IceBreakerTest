# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :canned_statement do
    sequence(:body){|n| "Canned Statement ##{n}"}
  end
end
