class ObservationDiaryRecordDecorator
  include Decore
  include ActionView::Helpers::TagHelper
  include ActionView::Context
  include ActionView::Helpers::UrlHelper

  def students_labels(selected_id)
    return unless component.students

    student_cell = all_students.count == component.students.count ? 'Todos' : student_label_for(component.students.distinct, selected_id)

    student_cell
  end

  def student_label_for(students, selected_id)
    students.map { |student|
      student_class = 'student-name'
      student_class += ' danger' if selected_id == student.id
      content_tag(:span, student, class: student_class)
    }.join(', ').html_safe
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
