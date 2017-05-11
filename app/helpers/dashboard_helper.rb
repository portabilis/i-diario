module DashboardHelper
  GLOBAL_FREQUENCY_ICONS = {
    'present' => 'fa fa-check-circle',
    'not_present' => 'fa fa-times-circle',
    'unreleased' => 'fa fa-question-circle'
  }

  GLOBAL_FREQUENCY_COLORS = {
    'present' => 'success',
    'not_present' => 'danger',
    'unreleased' => 'warning'
  }

  GLOBAL_FREQUENCY_TEXTS = {
    'present' => 'Presente',
    'not_present' => 'Ausente',
    'unreleased' => 'Não informado'
  }

  def global_frequency_info frequency
    "<span class='#{GLOBAL_FREQUENCY_COLORS[frequency]}'><i class='#{GLOBAL_FREQUENCY_ICONS[frequency]}'></i> #{GLOBAL_FREQUENCY_TEXTS[frequency]}</span>"
  end

  def student_situation student_present
    tag_class = student_present ? "label bg-color-greenDark" : "label bg-color-blueLight"
    tag_text = student_present ? "Presente" : "Ausente&nbsp;"
    tag_icon = student_present ? "fa-check" : "fa-user-times"
    content_tag(:span, class: tag_class) do
      content_tag(:i,'', class: 'fa '+tag_icon) + ' ' + raw(tag_text)
    end
  end
end