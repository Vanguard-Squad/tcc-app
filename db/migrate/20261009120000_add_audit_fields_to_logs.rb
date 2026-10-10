class AddAuditFieldsToLogs < ActiveRecord::Migration[8.1]
  def change
    add_reference :logs, :company, foreign_key: true
    add_reference :logs, :auditable, polymorphic: true
    add_column :logs, :details, :jsonb, default: {}, null: false
    add_column :logs, :ip_address, :string
    add_index :logs, %i[company_id created_at]
  end
end
