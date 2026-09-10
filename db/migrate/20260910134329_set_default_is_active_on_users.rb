class SetDefaultIsActiveOnUsers < ActiveRecord::Migration[8.1]
  def change
    change_column_default :users, :is_active, from: nil, to: true
  end
end
