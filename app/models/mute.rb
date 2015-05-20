class Mute < ActiveRecord::Base

  TIMER = 5

  def blocked_timer
    start_time = self.created_at.to_time
    passed_time = (5 - TimeDifference.between(Time.now, start_time).in_minutes).to_i
  end

end
