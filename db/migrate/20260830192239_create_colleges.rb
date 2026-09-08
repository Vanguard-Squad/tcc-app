class CreateColleges < ActiveRecord::Migration[8.1]
  def change
    create_table :colleges do |t|
      t.string :name
      t.boolean :is_active
      t.references :address, null: false, foreign_key: true

      t.timestamps
    end
  end
end
