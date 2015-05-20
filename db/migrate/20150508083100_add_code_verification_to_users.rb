class AddCodeVerificationToUsers < ActiveRecord::Migration
  def change
    add_column :users, :password_code, :string
  end
end
