class Session < ActiveRecord::Base
  belongs_to :user

  def session_time_out
    id = self.id
    scheduler = Rufus::Scheduler.new
    scheduler.at Time.now + 1.hours do
      session = Session.find_by_id(id)
      if Time.now - session.updated_at > 1.hours
        session.destroy
      end
    end
  end

end