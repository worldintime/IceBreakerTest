class AddFacebookToUser < ActiveRecord::Migration
  def change
    add_column :users, :facebook_uid, :string
    add_column :users, :facebook_avatar, :string
  end
end
