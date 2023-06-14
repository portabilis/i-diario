class AddPositionToContentsTeachingPlans < ActiveRecord::Migration[4.2]
  def change
    add_column :contents_teaching_plans, :position, :integer, null: true
  end
end
