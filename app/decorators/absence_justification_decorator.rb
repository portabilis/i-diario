class AbsenceJustificationDecorator
  include Decore
  include ActionView::Helpers::TagHelper
  include ActionView::Context
  include ActionView::Helpers::UrlHelper

  def author(current_user, employee_or_admin)
    AbsenceJustificationAuthorFetcher.new(component, current_user, employee_or_admin).author
  end

  def students_labels
    return unless component.students

    student_cell = student_label_for(component.students.limit(3))

    student_cell.concat(collapse_panel) if component.students.size > 3

    student_cell
  end

  def student_label_for(students)
    students.map { |student|
      content_tag(:p, content_tag(:span, student, class: 'label label-info label-list'))
    }.join.html_safe
  end

  def collapse_panel
    content_tag(
      :div,
      class: 'panel-group',
      id: "accordion#{component.id}",
      role: 'tablist',
      'aria-multiselectable': 'true',
      style: 'margin: 0px'
    ) do
      content_tag(
        :div,
        class: 'panel-collapse collapse',
        id: "collapse#{component.id}",
        role: 'tabpanel',
        'aria-labelledby': "heading#{component.id}"
      ) {
        content_tag(:div, class: 'panel-body', style: 'padding: 0px') do
          student_label_for(component.students.offset(3))
        end
      } +
        content_tag(:div, class: 'panel-default', style: 'border: none') {
          content_tag(:div, role: 'tab', id: "heading#{component.id}") do
            link_to(
              "Mostrar mais #{component.students.size - 3}",
              "#collapse#{component.id}",
              class: 'collapsed',
              id: "show_more_#{component.id}",
              'data-toggle': 'collapse',
              'data-parent': "#accordion#{component.id}",
              'data-more': component.students.size - 3,
              'aria-expanded': 'true',
              'aria-controls': "collapse#{component.id}"
            )
          end
        }
    end
  end
end
