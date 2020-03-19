class DeleteSchoolCalendarClassroomsWithNullClassroomId < ActiveRecord::Migration
  def change
    SchoolCalendarClassroom.where(classroom_id: nil).each(&:destroy)
  end
end
