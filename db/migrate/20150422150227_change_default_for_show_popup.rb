class ChangeDefaultForShowPopup < ActiveRecord::Migration
  def change
    change_column :users, :show_popup, :boolean, default: true
  end
end
