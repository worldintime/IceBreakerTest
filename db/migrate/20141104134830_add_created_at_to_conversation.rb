class AddCreatedAtToConversation < ActiveRecord::Migration
  def change
    add_column :conversations, :initial_created_at, :datetime
    add_column :conversations, :reply_created_at, :datetime
    add_column :conversations, :finished_created_at, :datetime
  end
end
