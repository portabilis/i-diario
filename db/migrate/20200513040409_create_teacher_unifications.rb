class CreateTeacherUnifications < ActiveRecord::Migration[4.2]
  def change
    create_table :teacher_unifications do |t|
      t.belongs_to :teacher
      t.datetime :unified_at
      t.boolean :active
      t.timestamps
    end
  end
end
