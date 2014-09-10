class ChangeUser < ActiveRecord::Migration
  
  def change
    change_table :users do |t|
      t.string :facebook_id
      t.string :oauth_token
      t.datetime :oauth_expires_at
    end	
  end
end
