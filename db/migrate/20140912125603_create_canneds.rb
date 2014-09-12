class CreateCanneds < ActiveRecord::Migration
  def change
    create_table :canneds do |t|
      t.text :body
      t.integer :user_id

      t.timestamps
    end
  end
end
