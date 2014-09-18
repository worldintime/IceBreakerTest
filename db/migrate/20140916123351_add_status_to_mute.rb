class AddStatusToMute < ActiveRecord::Migration
  def change
    add_column :mutes, :status, :string
  end
end
