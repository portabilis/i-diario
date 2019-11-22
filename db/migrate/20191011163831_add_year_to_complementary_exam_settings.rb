class AddYearToComplementaryExamSettings < ActiveRecord::Migration
  def change
    add_column :complementary_exam_settings, :year, :integer
  end
end
