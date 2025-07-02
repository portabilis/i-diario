class AddCpfToTeachers < ActiveRecord::Migration[5.0]
  def change
    add_column :teachers, :cpf, :string
  end
end
