class CreateStudents < ActiveRecord::Migration[8.1]
  def change
    create_table :students do |t|
      t.string :name
      t.string :cpf
      t.date :birthdate
      t.string :gender
      t.references :user, null: false, foreign_key: true
      t.references :address, null: false, foreign_key: true
      t.references :college, null: false, foreign_key: true

      t.timestamps
    end
  end
end
