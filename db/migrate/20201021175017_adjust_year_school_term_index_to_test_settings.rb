class AdjustYearSchoolTermIndexToTestSettings < ActiveRecord::Migration[4.2]
  def change
    remove_index :test_settings, column: [:year, :school_term]

    add_index(
      :test_settings,
      [:year, :school_term],
      unique: true,
      where: "school_term IS NOT NULL AND school_term <> ''"
    )
  end
end
