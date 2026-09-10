class AddUniqueIndexesForRegistration < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :username, unique: true
    add_index :companies, :cnpj, unique: true
  end
end
