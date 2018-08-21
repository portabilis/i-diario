class AddMaxDescriptiveExamCharacterCountToGeneralConfigurations < ActiveRecord::Migration
  def change
    add_column :general_configurations, :max_descriptive_exam_character_count, :integer
  end
end
