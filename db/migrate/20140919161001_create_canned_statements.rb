class CreateCannedStatements < ActiveRecord::Migration
  def change
    create_table :canned_statements do |t|
      t.text :body
      t.integer :user_id
    end
  end
end
