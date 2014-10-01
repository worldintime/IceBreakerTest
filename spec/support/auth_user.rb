module AuthUser
  def auth_user!(user = nil)
    if user
      user.confirm!
      user.sessions << create(:session)
      user.save!
    else
      user = create(:user_confirmed, sessions: [ create(:session) ])
    end
  end
end
