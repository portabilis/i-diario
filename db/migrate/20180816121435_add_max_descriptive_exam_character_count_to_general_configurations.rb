class AddMaxDescriptiveExamCharacterCountToGeneralConfigurations < ActiveRecord::Migration[4.2]
  def change
    add_column :general_configurations, :max_descriptive_exam_character_count, :integer
  end
end
