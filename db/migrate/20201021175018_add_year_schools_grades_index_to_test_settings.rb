class AddYearSchoolsGradesIndexToTestSettings < ActiveRecord::Migration
  def change
    add_index :test_settings, [:year, :unities, :grades], unique: true, where: "unities <> '{}'"
  end
end
