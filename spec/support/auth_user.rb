module AuthUser
  def auth_user!(user = nil)
    if user
      user.confirmed_at = Time.now
      user.sessions << create(:session)
      user.save!
    else
      create(:user, confirmed_at: Time.now, sessions: [ create(:session) ])
    end
  end
end