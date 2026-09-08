class CreateCheckins < ActiveRecord::Migration[8.1]
  def change
    create_table :checkins do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true
      t.boolean :status
      t.datetime :boarded_initial
      t.datetime :disembarked_college
      t.datetime :boarded_college
      t.datetime :disembarked_final
      t.datetime :date

      t.timestamps
    end
  end
end
