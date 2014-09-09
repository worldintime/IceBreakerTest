class CreateSessions < ActiveRecord::Migration
  def change
    create_table :sessions do |t|
      t.string :auth_token
      t.string :device
      t.string :device_token
      t.integer :user_id
      t.datetime :updated_at
      t.string :api_key

      t.timestamps
    end
  end
end
