class AddExamSettingTypeAndSchoolTermToTestSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :test_settings, :exam_setting_type, :string, null: true
    add_column :test_settings, :school_term,       :string, null: true

    execute <<-SQL
      UPDATE test_settings SET exam_setting_type = 'general';
    SQL

    change_column :test_settings, :exam_setting_type, :string, null: false

    add_index :test_settings, [:year, :school_term], unique: true
  end
end
