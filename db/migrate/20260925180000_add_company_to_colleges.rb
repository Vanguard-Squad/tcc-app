class AddCompanyToColleges < ActiveRecord::Migration[8.1]
  def up
    add_reference :colleges, :company, foreign_key: true

    # Faculdades existentes passam a pertencer à empresa dos seus alunos; as
    # demais ficam com a primeira empresa cadastrada.
    execute <<~SQL
      UPDATE colleges SET company_id = (
        SELECT users.company_id FROM students
        JOIN users ON users.id = students.user_id
        WHERE students.college_id = colleges.id AND users.company_id IS NOT NULL
        LIMIT 1
      )
    SQL
    execute "UPDATE colleges SET company_id = (SELECT MIN(id) FROM companies) WHERE company_id IS NULL"
    execute "DELETE FROM colleges WHERE company_id IS NULL AND id NOT IN (SELECT college_id FROM students)"

    change_column_null :colleges, :company_id, false
  end

  def down
    remove_reference :colleges, :company, foreign_key: true
  end
end
