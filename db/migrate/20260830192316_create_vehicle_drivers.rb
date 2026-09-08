class CreateVehicleDrivers < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicle_drivers do |t|
      t.references :driver, null: false, foreign_key: true
      t.references :vehicle, null: false, foreign_key: true
      t.string :week_day

      t.timestamps
    end
  end
end
