class CreateArchives < ActiveRecord::Migration[8.1]
  def change
    create_table :archives do |t|
      t.references :user, null: false, foreign_key: true
      t.string :archive_type
      t.string :name
      t.binary :file
      t.string :service_path

      t.timestamps
    end
  end
end
