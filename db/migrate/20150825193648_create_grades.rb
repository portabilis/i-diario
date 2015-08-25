class CreateGrades < ActiveRecord::Migration
  def change
    create_table :grades do |t|
      t.string :description
      t.string :api_code
      t.references :course, index: true

      t.timestamps
    end
    add_foreign_key :grades, :courses
  end
end
