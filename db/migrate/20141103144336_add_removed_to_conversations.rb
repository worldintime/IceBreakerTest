class AddRemovedToConversations < ActiveRecord::Migration
  def change
    add_column :conversations, :removed_by_sender, :boolean, default: false
    add_column :conversations, :removed_by_receiver, :boolean, default: false
  end
end
