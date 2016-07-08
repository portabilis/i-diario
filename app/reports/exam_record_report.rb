require "prawn/measurement_extensions"

class ExamRecordReport
  include Prawn::View

  def self.build(entity_configuration, teacher, year, school_calendar_step, test_setting, daily_notes, students)
    new.build(entity_configuration, teacher, year, school_calendar_step, test_setting, daily_notes, students)
  end

  def initialize
    @document = Prawn::Document.new(page_size: 'A4',
                                    page_layout: :landscape,
                                    left_margin: 5.mm,
                                    right_margin: 5.mm,
                                    top_margin: 5.mm,
                                    bottom_margin: 5.mm)
  end

  def build(entity_configuration, teacher, year, school_calendar_step, test_setting, daily_notes, students)
    @entity_configuration = entity_configuration
    @teacher = teacher
    @year = year
    @school_calendar_step = school_calendar_step
    @test_setting = test_setting
    @daily_notes = daily_notes
    @students = students

    header

    daily_notes_table

    footer

    self
  end

  protected

  attr_accessor :any_student_with_dependence

  private

  def header
    exam_header = make_cell(content: 'Registro de avaliações', size: 12, font_style: :bold, background_color: 'DEDEDE', height: 20, padding: [2, 2, 4, 4], align: :center, colspan: 5)
    begin
      logo_cell = make_cell(image: open(@entity_configuration.logo.url), fit: [50, 50], width: 70, rowspan: 4, position: :center, vposition: :center)
    rescue
      logo_cell = make_cell(content: '', width: 70, rowspan: 4)
    end

    entity_name = @entity_configuration ? @entity_configuration.entity_name : ''
    organ_name = @entity_configuration ? @entity_configuration.organ_name : ''

    entity_organ_and_unity_cell = make_cell(content: "#{entity_name}\n#{organ_name}\n#{@daily_notes.first.unity.name}", size: 12, leading: 1.5, align: :center, valign: :center, rowspan: 4, padding: [6, 0, 8, 0])
    classroom_header = make_cell(content: 'Turma', size: 8, font_style: :bold, width: 100, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    year_header = make_cell(content: 'Ano letivo', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    step_header = make_cell(content: 'Etapa', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    discipline_header = make_cell(content: 'Disciplina', size: 8, font_style: :bold, width: 200, colspan: 2, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    teacher_header = make_cell(content: 'Professor', size: 8, font_style: :bold, width: 200, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    classroom_cell = make_cell(content: @daily_notes.first.classroom.description, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)
    year_cell = make_cell(content: @year.to_s, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)
    step_cell = make_cell(content: @school_calendar_step.to_s, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)
    discipline_cell = make_cell(content: (@daily_notes.first.discipline ? @daily_notes.first.discipline.description : 'Geral'), size: 10, colspan: 2, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)
    teacher_cell = make_cell(content: @teacher.name, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)

    first_table_data = [[exam_header],
                        [logo_cell, entity_organ_and_unity_cell, classroom_header, year_header, step_header],
                        [classroom_cell, year_cell, step_cell],
                        [discipline_header, teacher_header],
                        [discipline_cell, teacher_cell]]

    repeat(:all) do
      table(first_table_data, width: bounds.width) do
        cells.border_width = 0.25
        row(0).border_top_width = 0.25
        row(-1).border_bottom_width = 0.25
        column(0).border_left_width = 0.25
        column(-1).border_right_width = 0.25
      end
    end
  end

  def daily_notes_table
    averages = {}
    self.any_student_with_dependence = false
    students_ids = fetch_students_ids

    students_ids.each do |student_id|
      averages[student_id] = StudentAverageCalculator.new(Student.find(student_id)).calculate(@daily_notes.first.classroom, @daily_notes.first.discipline, @school_calendar_step.id)
    end

    sliced_daily_notes = @daily_notes.each_slice(10).to_a

    sliced_daily_notes.each_with_index do |daily_notes_slice, index|
      avaliations = []
      students = {}

      daily_notes_slice.each do |daily_note|
        avaliations << make_cell(content: "#{daily_note.avaliation.to_s}", font_style: :bold, background_color: 'FFFFFF', align: :center)
        avaliations << make_cell(content: "Rec. #{daily_note.avaliation.to_s}", font_style: :bold, background_color: 'FFFFFF', align: :center) if daily_note.avaliation.recovery_diary_record

        students_ids.each do |student_id|
          if exempted_avaliation?(student_id, daily_note.avaliation_id)
            student_note = ExemptedDailyNoteStudent.new
          else
            student_note = DailyNoteStudent
            .find_by(
              student_id: student_id,
              daily_note_id: daily_note.id
            ) || NullDailyNoteStudent.new
          end

          student = Student.find(student_id)

          self.any_student_with_dependence = any_student_with_dependence || student_note.dependence?

          (students[student_id] ||= {})[:name] = student.name

          students[student_id] = {} if students[student_id].nil?
          students[student_id][:dependence] = students[student_id][:dependence] || student_note.dependence?

          (students[student_id][:scores] ||= []) << make_cell(content: student_note.note.to_s, align: :center)

          (students[student_id][:scores] ||= []) << make_cell(content: student_note.recovery_note.to_s, align: :center) if daily_note.avaliation.recovery_diary_record.present?
        end
      end

      sequential_number_header = make_cell(content: 'Nº', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center, width: 15)
      student_name_header = make_cell(content: 'Nome do aluno', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center, width: 170)
      average_header = make_cell(content: 'Média', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center, width: 30)

      first_headers_and_cells = [sequential_number_header, student_name_header].concat(avaliations)
      (10 - avaliations.count).times { first_headers_and_cells << make_cell(content: '', background_color: 'FFFFFF', width: 50) }
      first_headers_and_cells << average_header

      students_cells = []
      students = students.sort_by { |(key, value)| value[:dependence] ? 1 : 0 }
      students.each_with_index do |(key, value), index|
        sequence_cell = make_cell(content: (index + 1).to_s, align: :center)
        student_cells = [sequence_cell, { content: (value[:dependence] ? '* ' : '') + value[:name] }].concat(value[:scores])
        data_column_count = value[:scores].count + (value[:recoveries].nil? ? 0 : value[:recoveries].count)

        (10 - data_column_count).times { student_cells << nil }
        if daily_notes_slice == sliced_daily_notes.last
          average = averages[key]
          student_cells << make_cell(content: "#{average}", font_style: :bold, align: :center)
        else
          student_cells << make_cell(content: '-', font_style: :bold, align: :center)
        end
        students_cells << student_cells
      end

      (10 - students_cells.count).times do
        sequence_cell = make_cell(content: (students_cells.count + 1).to_s, align: :center)
        scores = []
        10.times { scores << make_cell(content: '', align: :center) }
        student_cells = [sequence_cell, { content: '', colspan: 2 }].concat(scores)
        student_cells << make_cell(content: '', align: :center)
        students_cells << student_cells
      end

      sliced_students_cells = students_cells.each_slice(25).to_a
      sliced_students_cells.each_with_index do |students_cells_slice, index|
        data = [
          first_headers_and_cells
        ]
        data.concat(students_cells_slice)

        bounding_box([0, 482], width: bounds.width) do
          table(data, row_colors: ['FFFFFF', 'DEDEDE'], cell_style: { size: 8, padding: [2, 2, 2, 2] }, width: bounds.width) do |t|
            t.cells.border_width = 0.25
            t.before_rendering_page do |page|
              page.row(0).border_top_width = 0.25
              page.row(-1).border_bottom_width = 0.25
              page.column(0).border_left_width = 0.25
              page.column(-1).border_right_width = 0.25
            end
          end
        end

        start_new_page if index < sliced_students_cells.count - 1
      end

      start_new_page if index < sliced_daily_notes.count - 1
    end
  end

  def footer
    repeat(:all) do
      draw_text('Assinatura do(a) professor(a):', size: 8, style: :bold, at: [0, 0])
      draw_text('____________________________', size: 8, at: [117, 0])

      draw_text('Assinatura do(a) coordenador(a):', size: 8, style: :bold, at: [259, 0])
      draw_text('____________________________', size: 8, at: [388, 0])

      draw_text('Data:', size: 8, style: :bold, at: [528, 0])
      draw_text('________________', size: 8, at: [549, 0])

      draw_text('Legendas: N - Não enturmado, D - Dispensado da avaliação', size: 8, at: [0, 17])
      draw_text('* Alunos cursando dependência', size: 8, at: [0, 32]) if self.any_student_with_dependence
    end

    string = "Página <page> de <total>"
    options = { at: [bounds.right - 150, 6],
                width: 150,
                size: 8,
                align: :right }
    number_pages(string, options)
  end

  def fetch_students_ids
    students_ids = []
    @daily_notes.each do |daily_note|
      daily_note.students.each do |student|
        students_ids << student.student.id
      end
    end
    students_ids.uniq!
    order_students_by_name(students_ids)
  end

  def order_students_by_name(students_ids)
    students = Student.where(id: students_ids).ordered
    students_ids = students.collect(&:id)
    students_ids
  end

  def exempted_avaliation?(student_id, avaliation_id)
    avaliation_is_exempted = AvaliationExemption
      .by_student(student_id)
      .by_avaliation(avaliation_id)
      .any?
    avaliation_is_exempted
  end
end
