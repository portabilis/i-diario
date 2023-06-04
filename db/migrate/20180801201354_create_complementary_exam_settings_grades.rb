class CreateComplementaryExamSettingsGrades < ActiveRecord::Migration[4.2]
  def change
    create_table :complementary_exam_settings_grades do |t|
      t.references :grade, index: { name: 'idx_cesg_grade_id' }
      t.references :complementary_exam_setting, index: { name: 'idx_cesg_complementary_exam_setting_id' }
    end
    add_foreign_key :complementary_exam_settings_grades, :grades, name: 'fk_cesg_grade_id'
    add_foreign_key :complementary_exam_settings_grades, :complementary_exam_settings, name: 'fk_cesg_complementary_exam_setting_id'
  end
end
