class AddMinimumScoreToTestSettings < ActiveRecord::Migration
  def change
    remove_column :test_settings, :minimum_score

    add_column :test_settings, :minimum_score, :integer, default: 0, null: false
  end
end
