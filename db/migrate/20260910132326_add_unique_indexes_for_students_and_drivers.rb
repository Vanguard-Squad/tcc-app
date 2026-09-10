class AddUniqueIndexesForStudentsAndDrivers < ActiveRecord::Migration[8.1]
  def change
    add_index :students, :cpf, unique: true
    add_index :drivers, :drive_license, unique: true
  end
end
