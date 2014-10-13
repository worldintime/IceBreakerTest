# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :conversation do
    sender_id 1
    receiver_id 2
    status 'Closed'
    initial_viewed false
    reply_viewed false
    finished_viewed false
  end
end
