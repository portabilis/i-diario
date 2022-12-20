class ObservationDiaryRecordDecorator
  include Decore
  include ActionView::Helpers::TagHelper
  include ActionView::Context
  include ActionView::Helpers::UrlHelper

  def students_labels
    return unless component.students

    student_cell = all_students.count == component.students.count ? 'Todos' : student_label_for(component.students)

    student_cell
  end

  def student_label_for(students)
    students.join(', ')
  end

  def all_students
    student_enrollments = StudentEnrollmentsList.new(
      classroom: component.classroom_id,
      discipline: nil,
      date: component.date,
      search_type: :by_date
    ).student_enrollments
  end
end
