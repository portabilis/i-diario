class PopulateFieldClassroomApiCodeInSchoolCalenadarClassrooms < ActiveRecord::Migration[4.2]
  def change
    school_calendar_classrooms = SchoolCalendarClassroom.joins(:classroom)
                                                        .select(
                                                          'school_calendar_classrooms.id AS id,
                                                          classrooms.api_code as classroom_api_code'
                                                        )

    school_calendar_classrooms.each do |school_calendar_classroom|
      calendar_classroom = SchoolCalendarClassroom.find(school_calendar_classroom.id)
      calendar_classroom.without_auditing do
        calendar_classroom.update!(classroom_api_code: school_calendar_classroom.classroom_api_code)
      end
    end
  end
end
