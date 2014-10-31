class Mute < ActiveRecord::Base

  def blocked_timer
    start_time = self.created_at.to_time
    passed_time = (60 - TimeDifference.between(Time.now, start_time).in_minutes).to_i
  end

end
