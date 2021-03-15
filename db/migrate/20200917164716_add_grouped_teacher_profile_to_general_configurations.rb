class AddGroupedTeacherProfileToGeneralConfigurations < ActiveRecord::Migration
  def change
    add_column :general_configurations, :grouped_teacher_profile, :boolean, default: false, null: false
  end
end
