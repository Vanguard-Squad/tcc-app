class MoveCompanyFromCollegesToAddresses < ActiveRecord::Migration[8.1]
  def up
    add_reference :addresses, :company, foreign_key: true

    # Cada endereço herda a empresa do registro a que pertence. A ordem define
    # a prioridade caso um mesmo endereço seja usado por mais de um registro.
    execute <<~SQL
      UPDATE addresses SET company_id = companies.id
      FROM companies WHERE companies.address_id = addresses.id AND addresses.company_id IS NULL
    SQL
    execute <<~SQL
      UPDATE addresses SET company_id = colleges.company_id
      FROM colleges WHERE colleges.address_id = addresses.id AND addresses.company_id IS NULL
    SQL
    execute <<~SQL
      UPDATE addresses SET company_id = users.company_id
      FROM students JOIN users ON users.id = students.user_id
      WHERE students.address_id = addresses.id AND addresses.company_id IS NULL AND users.company_id IS NOT NULL
    SQL
    execute <<~SQL
      UPDATE addresses SET company_id = routes.company_id
      FROM stops JOIN routes ON routes.id = stops.route_id
      WHERE stops.address_id = addresses.id AND addresses.company_id IS NULL
    SQL

    remove_reference :colleges, :company, foreign_key: true
  end

  def down
    add_reference :colleges, :company, foreign_key: true
    execute <<~SQL
      UPDATE colleges SET company_id = addresses.company_id
      FROM addresses WHERE addresses.id = colleges.address_id
    SQL
    remove_reference :addresses, :company, foreign_key: true
  end
end
