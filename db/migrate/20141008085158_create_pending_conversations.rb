class CreatePendingConversations < ActiveRecord::Migration
  def change
    create_table :pending_conversations do |t|
      t.integer :sender_id
      t.integer :receiver_id
      t.integer :conversation_id
      t.timestamps
    end
  end
end
