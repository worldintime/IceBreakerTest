class AddLocationsToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.string :address
      t.float :latitude
      t.float :longitude

      add_index :users, :latitude
      add_index :users, :longitude
    end
  end
end
