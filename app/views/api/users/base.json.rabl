attributes :id, :first_name, :last_name, :user_name, :gender, :address, :latitude, :longitude, :facebook_avatar, :sent_rating, :received_rating

node :avatar do |user|
  user.avatar.url(:thumb)
end

node :status do
  @status
end

node :blocked do
    @blocked
end