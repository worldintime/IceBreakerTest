<<<<<<< HEAD
collection :@designated_users => :users
attributes :id, :first_name, :last_name, :address, :latitude, :longitude, :avatar, :sent_rating, :received_rating
=======
collection false

node :users_in_radius do
  @users_in_radius.map do |user|
    partial("api/users/base", object: user)
  end
end

node :users_out_of_radius do
  @users_out_of_radius.map do |user|
    partial("api/users/base", object: user)
  end
end
>>>>>>> c08fd95f2621e2f5b597be149551b05c57eb836e
