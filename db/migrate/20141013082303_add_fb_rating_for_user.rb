class AddFbRatingForUser < ActiveRecord::Migration
  def change
    add_column :users, :facebook_rating, :integer
  end
end
