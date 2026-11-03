class CreateContracts < ActiveRecord::Migration[8.1]
  def change
    create_table :contracts do |t|
      t.references :student, null: false, foreign_key: true, index: { unique: true }
      t.string :status, null: false, default: "pending"
      t.datetime :submitted_at
      t.datetime :reviewed_at
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.text :rejection_reason

      t.timestamps
    end
  end
end
