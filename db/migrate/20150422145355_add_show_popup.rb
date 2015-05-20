class AddShowPopup < ActiveRecord::Migration
  def change
    add_column :users, :show_popup, :boolean, default: false	
  end
end
