class Session < ActiveRecord::Base
  belongs_to :user
  reverse_geocoded_by :latitude, :longitude
  after_validation :reverse_geocode
end
