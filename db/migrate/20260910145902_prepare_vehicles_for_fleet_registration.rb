class PrepareVehiclesForFleetRegistration < ActiveRecord::Migration[8.1]
  def change
    change_column_null :vehicles, :route_id, true
    change_column_default :vehicles, :seats_busy, from: nil, to: 0
    change_column_default :vehicles, :is_active, from: nil, to: true

    add_index :vehicles, :license_plate, unique: true
  end
end
