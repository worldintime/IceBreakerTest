class AddLocationUpdatedAtToUser < ActiveRecord::Migration
  def change
    add_column :users, :location_updated_at, :timestamp
    add_index :users, :location_updated_at
  end
end
