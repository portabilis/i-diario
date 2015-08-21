# encoding: utf-8

require "prawn/measurement_extensions"

class ExamRecordReport
  include Prawn::View

  def self.build(entity_configuration, teacher, year, school_calendar_step, test_setting, daily_notes)
    new.build(entity_configuration, teacher, year, school_calendar_step, test_setting, daily_notes)
  end

  def initialize
    @document = Prawn::Document.new(page_size: 'A4',
                                    page_layout: :landscape,
                                    left_margin: 5.mm,
                                    right_margin: 5.mm,
                                    top_margin: 5.mm,
                                    bottom_margin: 5.mm)
  end

  def build(entity_configuration, teacher, year, school_calendar_step, test_setting, daily_notes)
    @entity_configuration = entity_configuration
    @teacher = teacher
    @year = year
    @school_calendar_step = school_calendar_step
    @test_setting = test_setting
    @daily_notes = daily_notes

    header

    daily_notes_table

    footer

    self
  end

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
    @daily_notes.each do |daily_note|
      daily_note.students.each do |student|
        ((averages[student.student.id] ||= {})[:sum_scores] ||= 0)
        averages[student.student.id][:sum_scores] = averages[student.student.id][:sum_scores] + (student.note ? student.note : 0)
        ((averages[student.student.id] ||= {})[:count_scores] ||= 0)
        averages[student.student.id][:count_scores] = averages[student.student.id][:count_scores] + 1
      end
    end

    sliced_daily_notes = @daily_notes.each_slice(10).to_a

    sliced_daily_notes.each_with_index do |daily_notes_slice, index|
      avaliations = []
      students = {}
      daily_notes_slice.each do |daily_note|
        avaliations << make_cell(content: "#{daily_note.avaliation.to_s}", font_style: :bold, background_color: 'FFFFFF', align: :center)
        daily_note.students.each do |student|
          (students[student.student.id] ||= {})[:name] = student.student.name
          (students[student.student.id][:scores] ||= []) << make_cell(content: student.note.to_s, align: :center)
        end
      end

      sequential_number_header = make_cell(content: 'Nº', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center)
      student_name_header = make_cell(content: 'Nome do aluno', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center)
      average_header = make_cell(content: 'Média', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center)

      first_headers_and_cells = [sequential_number_header, student_name_header].concat(avaliations)
      (10 - avaliations.count).times { first_headers_and_cells << make_cell(content: '', background_color: 'FFFFFF') }
      first_headers_and_cells << average_header

      students_cells = []
      students.each_with_index do |(key, value), index|
        sequence_cell = make_cell(content: (index + 1).to_s, align: :center)
        student_cells = [sequence_cell, { content: value[:name] }].concat(value[:scores])
        (10 - value[:scores].count).times { student_cells << nil }
        if daily_notes_slice == sliced_daily_notes.last
          average = @test_setting.fix_tests? ? averages[key][:sum_scores] : (averages[key][:sum_scores] / averages[key][:count_scores])
          student_cells << make_cell(content: "%.#{@test_setting.number_of_decimal_places}f" % average, font_style: :bold, align: :center)
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

      sliced_students_cells = students_cells.each_slice(30).to_a
      sliced_students_cells.each_with_index do |students_cells_slice, index|
        data = [
          first_headers_and_cells
        ]
        data.concat(students_cells_slice)

        column_widths = { 0 => 20, 12 => 40 }
        (2..11).each { |i| column_widths[i] = 50 }

        bounding_box([0, 482], width: bounds.width) do
          table(data, row_colors: ['FFFFFF', 'DEDEDE'], cell_style: { size: 8, padding: [2, 2, 2, 2] }, column_widths: column_widths, width: bounds.width) do |t|
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
      draw_text('______________________________', size: 8, at: [118, 0])

      draw_text('Data:', size: 8, style: :bold, at: [275, 0])
      draw_text('____________________', size: 8, at: [298, 0])
    end

    string = "Página <page> de <total>"
    options = { at: [bounds.right - 150, 6],
                width: 150,
                size: 8,
                align: :right }
    number_pages(string, options)
  end
end