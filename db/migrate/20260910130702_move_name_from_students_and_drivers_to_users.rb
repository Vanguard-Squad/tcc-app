class MoveNameFromStudentsAndDriversToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string

    remove_column :students, :name, :string
    remove_column :drivers, :name, :string
  end
end
