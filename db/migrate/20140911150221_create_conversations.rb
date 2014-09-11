class CreateConversations < ActiveRecord::Migration
  def change
    create_table :conversations do |t|
      t.integer :sender_id
      t.integer :receiver_id
      t.string :initial
      t.string :reply
      t.string :finished
      t.boolean :initial_viewed
      t.boolean :reply_viewed
      t.boolean :finished_viewed
      t.timestamps
    end
  end
end
