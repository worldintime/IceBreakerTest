class AddLocationToSession < ActiveRecord::Migration
  def change
    remove_column :users, :address
    remove_column :users, :latitude
    remove_column :users, :longitude
    add_column :sessions, :address, :string
    add_column :sessions, :latitude, :float
    add_column :sessions, :longitude, :float
  end
end
