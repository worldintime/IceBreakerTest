module AuthUser
  def auth_user!(user = nil)
    if user
      user.confirm!
      user.sessions << create(:session)
      user.save!
    else
      user = create(:user, sessions: [ create(:session) ], latitude: 40.7140, longitude: -74.0080)
      user.confirm!
      user
    end
  end
end
