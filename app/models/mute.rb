class Mute < ActiveRecord::Base
  has_one :conversation
end
