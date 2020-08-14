class AddPositionToContentsTeachingPlans < ActiveRecord::Migration
  def change
    add_column :contents_teaching_plans, :position, :integer, null: true
  end
end
