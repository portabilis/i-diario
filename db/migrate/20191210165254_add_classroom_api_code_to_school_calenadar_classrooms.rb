class AddClassroomApiCodeToSchoolCalenadarClassrooms < ActiveRecord::Migration[4.2]
  def change
    add_column :school_calendar_classrooms, :classroom_api_code, :string
  end
end
