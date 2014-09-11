class CreateMutes < ActiveRecord::Migration
  def change
    create_table :mutes do |t|
      t.integer :receiver_id
      t.integer :sender_id
      t.integer :conversation_id
      t.timestamps
    end
  end
end
