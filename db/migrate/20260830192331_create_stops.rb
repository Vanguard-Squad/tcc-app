class CreateStops < ActiveRecord::Migration[8.1]
  def change
    create_table :stops do |t|
      t.references :address, null: false, foreign_key: true
      t.references :route, null: false, foreign_key: true
      t.integer :step
      t.boolean :await_return
      t.integer :total_student_number

      t.timestamps
    end
  end
end
