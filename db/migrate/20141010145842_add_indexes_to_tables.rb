class AddIndexesToTables < ActiveRecord::Migration
  def change
    add_index :conversations, :sender_id
    add_index :conversations, :receiver_id
    add_index :pending_conversations, :sender_id
    add_index :pending_conversations, :receiver_id
    add_index :mutes, :sender_id
    add_index :mutes, :receiver_id
    add_index :sessions, :auth_token
  end
end
