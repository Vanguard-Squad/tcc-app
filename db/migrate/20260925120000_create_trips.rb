class CreateTrips < ActiveRecord::Migration[8.1]
  def change
    create_table :trips do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :driver, null: false, foreign_key: true
      t.string :direction, null: false
      t.string :status, null: false, default: "active"
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.float :latitude
      t.float :longitude
      t.datetime :position_at

      t.timestamps
    end

    add_index :trips, :vehicle_id, unique: true, where: "status = 'active'", name: "index_trips_on_active_vehicle"
  end
end
