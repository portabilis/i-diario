class AddSchoolCalendarClassroomStepsToIeducarApiExamPostings < ActiveRecord::Migration
  def change
    add_reference :ieducar_api_exam_postings, :school_calendar_classroom_step, index: { name: "index_classroom_step_on_api" }, foreign_key: true
  end
end
