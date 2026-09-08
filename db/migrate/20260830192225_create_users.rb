class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :role
      t.string :username
      t.string :password_digest
      t.boolean :is_active
      t.references :company, null: true

      t.timestamps
    end
  end
end
