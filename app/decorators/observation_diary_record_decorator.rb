class ObservationDiaryRecordDecorator
  include Decore
  include ActionView::Helpers::TagHelper
  include ActionView::Context
  include ActionView::Helpers::UrlHelper

  def students_labels(selected_id)
    return unless component.students

    student_cell = if all_students.count == component.students.count
                     content_tag(:span, 'Todos', class: 'student-name')
                   else
                     student_label_for(component.students.ordered.distinct, selected_id)
                   end

    student_cell
  end

  def student_label_for(students, selected_id)
    students.map { |student|
      student_class = 'student-name' if selected_id == student.id
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
