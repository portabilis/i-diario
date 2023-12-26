class CreateCourses < ActiveRecord::Migration[4.2]
  def change
    create_table :courses do |t|
      t.string :description
      t.string :api_code


      t.timestamps
    end
  end
end
