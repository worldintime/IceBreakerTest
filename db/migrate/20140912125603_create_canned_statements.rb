class CreateCannedStatements < ActiveRecord::Migration
  def change
    create_table :canned_statements do |t|
      t.text :body
      t.belongs_to :user

      t.timestamps
    end
  end
end
