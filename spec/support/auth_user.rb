module AuthUser
  def auth_user!(user = nil)
    if user
      user.confirm!
      user.sessions << create(:session)
      user.save!
    else
      create(:user_confirmed, sessions: [ create(:session) ], latitude: 40.7140, longitude: -74.0080)
    end
  end
end
