class AddYearToComplementaryExamSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :complementary_exam_settings, :year, :integer
  end
end
