class AddYearSchoolsGradesIndexToTestSettings < ActiveRecord::Migration[4.2]
  def change
    add_index :test_settings, [:year, :unities, :grades], unique: true, where: "unities <> '{}'"
  end
end
