class RenameUsernameToEmailOnUsers < ActiveRecord::Migration[8.1]
  def change
    rename_column :users, :username, :email
  end
end
