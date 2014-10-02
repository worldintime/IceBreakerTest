collection false

node :users_in_radius do
  @users_in_radius.map do |user|
  @blocked = user.blocked_to(@current_user.id)
    @status = user.search_results(@current_user.id)
    partial("api/users/base", object: user)
  end
end

node :users_out_of_radius do
  @users_out_of_radius.map do |user|
    partial("api/users/base", object: user)
  end
end
