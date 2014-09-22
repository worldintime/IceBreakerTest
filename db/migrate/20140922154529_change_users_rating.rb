class ChangeUsersRating < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.remove :rating
      t.integer :sent_rating, default: 0
      t.integer :received_rating, default: 0
    end
  end
end
