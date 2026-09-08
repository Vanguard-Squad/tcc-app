class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.string :street
      t.string :complement
      t.integer :number
      t.string :neighborhood
      t.string :country
      t.string :zip_code

      t.timestamps
    end
  end
end
