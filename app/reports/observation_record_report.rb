class ObservationRecordReport < BaseReportOld
  def title
    t(:title)
  end

  def body
    page_content do
      identification
      general_information
      signatures
    end
  end

  def translation_scope
    'reports.observation_record_report'.freeze
  end

  private

  def identification
    identification_table_header_cell = make_table_header_cell(
      t(:identification_header),
      colspan: 2
    )

    unity_header = make_row_header_cell(t(:unity), colspan: 2)
    unity_cell = make_content_cell(@form.unity.to_s, colspan: 2)
    discipline_header = make_row_header_cell(t(:discipline), width: 70)
    classroom_header = make_row_header_cell(t(:classroom))

    discipline_name = if @form.discipline_id.eql?('all')
                        'Todas'
                      elsif @form.discipline.present?
                        @form.discipline.to_s
                      else
                        t(:empty_discipline)
                      end

    classroom_name = @form.classroom_id.eql?('all') ? 'Todas' : @form.classroom.to_s

    discipline_cell = make_content_cell(discipline_name, width: 70)
    classroom_cell = make_content_cell(classroom_name)
    teacher_header = make_row_header_cell(t(:teacher))
    period_header = make_row_header_cell(t(:period))
    teacher_cell = make_content_cell(@form.teacher.to_s)

    period_cell = make_content_cell(
      t(:period_content, start_at: @form.start_at, end_at: form.end_at)
    )

    table_data = [
      [identification_table_header_cell],
      [unity_header],
      [unity_cell],
      [discipline_header, classroom_header],
      [discipline_cell, classroom_cell],
      [teacher_header, period_header],
      [teacher_cell, period_cell]
    ]

    table(table_data, width: bounds.width, header: true) do
      cells.border_width = 0.25
      row(0).border_top_width = 0.25
      row(-1).border_bottom_width = 0.25
      column(0).border_left_width = 0.25
      column(-1).border_right_width = 0.25
    end

    move_down GAP
  end

  def general_information
    general_information_header_cell = make_table_header_cell(
      t(:general_information),
      colspan: 5
    )

    title_general_information = [
      [general_information_header_cell]
    ]

    date_header = make_row_header_cell(t(:date), width: 62)
    students_header = make_row_header_cell(t(:students), width: 207)
    observations_header = make_row_header_cell(t(:observation))

    general_information_headers = [
      date_header,
      students_header,
      observations_header
    ]

    general_information_table_data = [general_information_headers]

    @form.observation_diary_records.each do |record|
      record.notes.each do |note|
        students = note.students.map(&:to_s).join(', ')

        date_cell = make_row_cell(record.localized.date, width: 62)
        students_cell = make_row_cell(students, width: 207)
        observation_cell = make_row_cell(note.description)

        general_information_table_data << [
          date_cell,
          students_cell,
          observation_cell
        ]
      end
    end

    table(title_general_information, width: bounds.width, header: true) do
      cells.border_width = 0.25
      row(0).border_top_width = 0.25
      row(-1).border_bottom_width = 0.25
      column(0).border_left_width = 0.25
      column(-1).border_right_width = 0.25
    end

    table(general_information_table_data, row_colors: [GRAY, WHITE], width: bounds.width, header: true) do
      cells.border_width = 0.25
      row(0).border_top_width = 0.25
      row(-1).border_bottom_width = 0.25
      column(0).border_left_width = 0.25
      column(-1).border_right_width = 0.25
    end
  end

  def signatures
    start_new_page if cursor < 45

    move_down 30

    text_box(t(:teacher_signature), size: 10, align: :center, at: [0, cursor], width: 260)
    text_box(t(:coordinator_signature), size: 10, align: :center, at: [306, cursor], width: 260)
  end
end
