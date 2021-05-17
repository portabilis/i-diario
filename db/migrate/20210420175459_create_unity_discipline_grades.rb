class CreateUnityDisciplineGrades < ActiveRecord::Migration
  def change
    create_table :unity_discipline_grades do |t|
      t.belongs_to :unity
      t.belongs_to :discipline
      t.belongs_to :grade
      t.integer :year
      t.timestamps
    end
  end
end
