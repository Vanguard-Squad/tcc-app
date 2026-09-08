class CreateVehicles < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicles do |t|
      t.integer :seats_busy
      t.integer :seats
      t.string :license_plate
      t.references :company, null: false, foreign_key: true
      t.references :route, null: false, foreign_key: true
      t.boolean :is_active

      t.timestamps
    end
  end
end
