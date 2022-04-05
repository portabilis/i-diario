class AddMinimumScoreToTestSettings < ActiveRecord::Migration
  def create
    add_column :test_settings, :minimum_score, :integer, default: 0, null: false
  end
end
