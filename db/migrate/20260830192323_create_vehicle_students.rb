class CreateVehicleStudents < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicle_students do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true
      t.boolean :is_return

      t.timestamps
    end
  end
end
