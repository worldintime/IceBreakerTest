attributes :id, :first_name, :last_name, :address, :latitude, :longitude, :avatar, :sent_rating, :received_rating,
           :user_name, :gender

node :status do
  @status
end

node do
  @blocked
end
