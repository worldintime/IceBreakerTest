class AddOpponentsShowEmailToConversations < ActiveRecord::Migration
  def change
    add_column :conversations, :show_opponents_email, :boolean, default: false	
  end
end
