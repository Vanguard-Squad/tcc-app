class CreateDrivers < ActiveRecord::Migration[8.1]
  def change
    create_table :drivers do |t|
      t.string :name
      t.date :birthdate
      t.string :drive_license
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
