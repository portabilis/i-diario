class DeleteSchoolCalendarClassroomsWithNullClassroomId < ActiveRecord::Migration[4.2]
  def change
    SchoolCalendarClassroom.where(classroom_id: nil).each(&:destroy)
  end
end
