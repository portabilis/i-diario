class AddClassroomApiCodeToSchoolCalenadarClassrooms < ActiveRecord::Migration
  def change
    add_column :school_calendar_classrooms, :classroom_api_code, :string
  end
end
