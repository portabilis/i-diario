require "prawn/measurement_extensions"

class AttendanceRecordReport
  include Prawn::View

  STUDENTS_BY_PAGE = 29

  def self.build(entity_configuration, teacher, year, start_at, end_at, daily_frequencies, student_ids, events)
    new.build(entity_configuration, teacher, year, start_at, end_at, daily_frequencies, student_ids, events)
  end

  def initialize
    @document = Prawn::Document.new(page_size: 'A4',
                                    page_layout: :landscape,
                                    left_margin: 5.mm,
                                    right_margin: 5.mm,
                                    top_margin: 5.mm,
                                    bottom_margin: 5.mm)
  end

  def build(entity_configuration, teacher, year, start_at, end_at, daily_frequencies, student_ids, events)
    @entity_configuration = entity_configuration
    @teacher = teacher
    @year = year
    @start_at = start_at
    @end_at = end_at
    @daily_frequencies = daily_frequencies
    @student_ids = student_ids
    @events = events

    self.legend = "Legenda: N - Não enturmado"

    content

    footer

    self
  end

  protected

  attr_accessor :any_student_with_dependence, :legend

  private

  def header
    attendance_header = make_cell(content: 'Registro de frequência', size: 12, font_style: :bold, background_color: 'DEDEDE', height: 20, padding: [2, 2, 4, 4], align: :center, colspan: 5)
    begin
      logo_cell = make_cell(image: open(@entity_configuration.logo.url), fit: [50, 50], width: 70, rowspan: 4, position: :center, vposition: :center)
    rescue
      logo_cell = make_cell(content: '', width: 70, rowspan: 4)
    end

    entity_name = @entity_configuration ? @entity_configuration.entity_name : ''
    organ_name = @entity_configuration ? @entity_configuration.organ_name : ''

    entity_organ_and_unity_cell = make_cell(content: "#{entity_name}\n#{organ_name}\n#{@daily_frequencies.first.unity.name}", size: 12, leading: 1.5, align: :center, valign: :center, rowspan: 4, padding: [6, 0, 8, 0])
    classroom_header = make_cell(content: 'Turma', size: 8, font_style: :bold, width: 100, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    year_header = make_cell(content: 'Ano letivo', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    period_header = make_cell(content: 'Período', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    discipline_header = make_cell(content: 'Disciplina', size: 8, font_style: :bold, width: 200, colspan: 2, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    teacher_header = make_cell(content: 'Professor', size: 8, font_style: :bold, width: 200, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    classroom_cell = make_cell(content: @daily_frequencies.first.classroom.description, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)
    year_cell = make_cell(content: @year.to_s, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)
    period_cell = make_cell(content: "De #{@start_at} a #{@end_at}", size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)
    discipline_cell = make_cell(content: (@daily_frequencies.first.discipline ? @daily_frequencies.first.discipline.description : 'Geral'), size: 10, colspan: 2, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)
    teacher_cell = make_cell(content: @teacher.name, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)

    first_table_data = [[attendance_header],
                        [logo_cell, entity_organ_and_unity_cell, classroom_header, year_header, period_header],
                        [classroom_cell, year_cell, period_cell],
                        [discipline_header, teacher_header],
                        [discipline_cell, teacher_cell]]

    table(first_table_data, width: bounds.width, header: true) do
      cells.border_width = 0.25
      row(0).border_top_width = 0.25
      row(-1).border_bottom_width = 0.25
      column(0).border_left_width = 0.25
      column(-1).border_right_width = 0.25
    end
  end

  def daily_frequencies_table
    self.any_student_with_dependence = false

    daily_frequencies = @daily_frequencies.reject { |daily_frequency| !daily_frequency.students.any? }

    frequencies_and_events = daily_frequencies.to_a + @events.to_a

    frequencies_and_events = frequencies_and_events.sort_by do |obj|
      event?(obj) ? obj.event_date : obj.frequency_date
    end
    sliced_frequencies_and_events = frequencies_and_events.each_slice(40).to_a

    sliced_frequencies_and_events.each_with_index do |frequencies_and_events_slice, index|
      class_numbers = []
      days = []
      months = []
      students = {}

      frequencies_and_events_slice.each do |daily_frequency_or_event|
        if event?(daily_frequency_or_event)
          school_calendar_event = daily_frequency_or_event
          legend = ", "+school_calendar_event.legend.to_s+" - "+school_calendar_event.description
          self.legend += legend unless self.legend.include?(legend)

          class_numbers << make_cell(content: "", background_color: 'FFFFFF', align: :center)
          days << make_cell(content: "#{school_calendar_event.event_date.day}", background_color: 'FFFFFF', align: :center)
          months << make_cell(content: "#{school_calendar_event.event_date.month}", background_color: 'FFFFFF', align: :center)

          @student_ids.each do |student_id|
            student = Student.find(student_id)
            (students[student_id] ||= {})[:name] = student.name
            students[student_id] = {} if students[student_id].nil?
            students[student_id][:absences] ||= 0
            (students[student_id][:attendances] ||= []) << make_cell(content: "#{school_calendar_event.legend}", align: :center)
          end
        else
          daily_frequency = daily_frequency_or_event
          class_numbers << make_cell(content: "#{daily_frequency.class_number}", background_color: 'FFFFFF', align: :center)
          days << make_cell(content: "#{daily_frequency.frequency_date.day}", background_color: 'FFFFFF', align: :center)
          months << make_cell(content: "#{daily_frequency.frequency_date.month}", background_color: 'FFFFFF', align: :center)
          @student_ids.each do |student_id|
            student_frequency = DailyFrequencyStudent.find_by(student_id: student_id, daily_frequency_id: daily_frequency.id) || NullDailyFrequencyStudent.new
            student = Student.find(student_id)
            (students[student_id] ||= {})[:name] = student.name
            students[student_id] = {} if students[student_id].nil?
            students[student_id][:dependence] = students[student_id][:dependence] || student_frequency.dependence?

            self.any_student_with_dependence = self.any_student_with_dependence || student_frequency.dependence?
            students[student_id][:absences] ||= 0
            if !student_frequency.present
              students[student_id][:absences] = students[student_id][:absences] + 1
            end
          (students[student_id][:attendances] ||= []) << make_cell(content: "#{student_frequency}", align: :center)
          end
        end
      end

      sequential_number_header = make_cell(content: 'Nº', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center, valign: :center, rowspan: 3)
      student_name_header = make_cell(content: 'Nome do aluno', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center, valign: :center, rowspan: 3)
      class_number_header = make_cell(content: 'Aula', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center, width: 20)
      day_header = make_cell(content: 'Dia', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center)
      month_header = make_cell(content: 'Mês', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center)
      absences_header = make_cell(content: 'Faltas', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center, valign: :center, rowspan: 3)

      first_headers_and_class_numbers_cells = [sequential_number_header, student_name_header, class_number_header].concat(class_numbers)
      (40 - class_numbers.count).times { first_headers_and_class_numbers_cells << make_cell(content: '', background_color: 'FFFFFF') }
      first_headers_and_class_numbers_cells << absences_header
      days_header_and_cells = [day_header].concat(days)
      (40 - days.count).times { days_header_and_cells << make_cell(content: '', background_color: 'FFFFFF') }
      months_header_and_cells = [month_header].concat(months)
      (40 - months.count).times { months_header_and_cells << make_cell(content: '', background_color: 'FFFFFF') }

      students_cells = []
      students = students.sort_by { |(key, value)| value[:dependence] ? 1 : 0 }
      sequence = 1
      sequence_reseted = false
      students.each do |key, value|
        if(!sequence_reseted && value[:dependence])
          sequence = 1
          sequence_reseted = true
        end

        sequence_cell = make_cell(content: sequence.to_s, align: :center)
        student_cells = [sequence_cell, { content: (value[:dependence] ? '* ' : '') + value[:name], colspan: 2 }].concat(value[:attendances])
        (40 - value[:attendances].count).times { student_cells << nil }
        student_cells << make_cell(content: value[:absences].to_s, align: :center)
        students_cells << student_cells

        sequence += 1
      end

      sliced_students_cells = students_cells.each_slice(STUDENTS_BY_PAGE).to_a
      sliced_students_cells.each_with_index do |students_cells_slice, index|
        data = [
          first_headers_and_class_numbers_cells,
          days_header_and_cells,
          months_header_and_cells
        ]
        data.concat(students_cells_slice)

        column_widths = { 0 => 20, 1 => 140, 43 => 30 }
        (3..42).each { |i| column_widths[i] = 13 }

        move_down 8

        table(data, row_colors: ['FFFFFF', 'DEDEDE'], cell_style: { size: 8, padding: [2, 2, 2, 2] }, column_widths: column_widths, width: bounds.width) do |t|
          t.cells.border_width = 0.25
          t.before_rendering_page do |page|
            page.row(0).border_top_width = 0.25
            page.row(-1).border_bottom_width = 0.25
            page.column(0).border_left_width = 0.25
            page.column(-1).border_right_width = 0.25
          end
        end

        text_box(self.legend, size: 8, at: [0, 30], width: 825, height: 20)
        start_new_page if index < sliced_students_cells.count - 1
      end

      text_box(self.legend, size: 8, at: [0, 30], width: 825, height: 20)
      self.legend = "Legenda: N - Não enturmado"
      start_new_page if index < sliced_frequencies_and_events.count - 1
    end
  end

  def content
    header
    daily_frequencies_table
  end

  def footer
    repeat(:all) do
      draw_text('Assinatura do(a) professor(a):', size: 8, style: :bold, at: [0, 0])
      draw_text('____________________________', size: 8, at: [117, 0])

      draw_text('Assinatura do(a) coordenador(a)/diretor(a):', size: 8, style: :bold, at: [259, 0])
      draw_text('____________________________', size: 8, at: [429, 0])

      draw_text('Data:', size: 8, style: :bold, at: [559, 0])
      draw_text('________________', size: 8, at: [581, 0])

      if(self.any_student_with_dependence)
        draw_text('* Alunos cursando dependência', size: 8, at: [0, 47])
      end
    end

    string = "Página <page> de <total>"
    options = { at: [bounds.right - 150, 6],
                width: 150,
                size: 8,
                align: :right }
    number_pages(string, options)
  end

  def event?(record)
    record.class.to_s == "SchoolCalendarEvent"
  end
end
