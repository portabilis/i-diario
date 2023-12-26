class CreateAvaliationsGrades < ActiveRecord::Migration[4.2]
  def change
    create_table :avaliations_grades do |t|
      t.belongs_to :avaliation
      t.belongs_to :grade
      t.timestamps
    end
  end
end
