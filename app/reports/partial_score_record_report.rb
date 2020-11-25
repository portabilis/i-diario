require 'action_view'

class PartialScoreRecordReport < BaseReport
  include ActionView::Helpers::NumberHelper

  def self.build(entity_configuration, year, school_calendar_step, students, unity, classroom, test_setting)
    new.build(entity_configuration, year, school_calendar_step, students, unity, classroom, test_setting)
  end

  def build(entity_configuration, year, school_calendar_step, students, unity, classroom, test_setting)
    @entity_configuration = entity_configuration
    @year = year
    @school_calendar_step = school_calendar_step
    @students = students
    @unity = unity
    @classroom = classroom
    @test_setting = test_setting
    @show_dispensation = false
    @display_header_on_all_reports_pages = true

    header
    body
    footer

    self
  end

  private

  def header
    header_cell = make_cell(content: 'Registro de notas parciais', size: 12, font_style: :bold, background_color: 'DEDEDE', height: 20, padding: [2, 2, 4, 4], align: :center, colspan: 2)
    begin
      logo_cell = make_cell(image: open(@entity_configuration.logo.url), fit: [50, 50], width: 70, rowspan: 4, position: :center, vposition: :center)
    rescue
      logo_cell = make_cell(content: '', width: 70, rowspan: 4)
    end

    entity_name = @entity_configuration ? @entity_configuration.entity_name : ''
    organ_name = @entity_configuration ? @entity_configuration.organ_name : ''

    entity_organ_and_unity_cell = make_cell(content: "#{entity_name}\n#{organ_name}\n#{@unity.name}", size: 12, leading: 1.5, align: :center, valign: :center, rowspan: 4, padding: [6, 0, 8, 0])

    header_table_data = [[header_cell],
                        [logo_cell, entity_organ_and_unity_cell]
                      ]

    page_header do
      table(header_table_data, width: bounds.width) do
        cells.border_width = 0.25
        row(0).border_top_width = 0.25
        row(-1).border_bottom_width = 0.25
        column(0).border_left_width = 0.25
        column(-1).border_right_width = 0.25
      end
    end
  end

  def identification(student)
    header_cell = make_cell(content: 'Identificação', size: 12, font_style: :bold, background_color: 'DEDEDE', height: 20, padding: [2, 2, 4, 4], align: :center, colspan: 2)

    unity_cell_header = make_cell(content: 'Unidade', size: 8, font_style: :bold, width: 100, borders: [:top, :left, :right], padding: [2, 2, 4, 4], colspan: 2)
    student_cell_header = make_cell(content: 'Aluno', size: 8, font_style: :bold, width: 100, borders: [:top, :left, :right], padding: [2, 2, 4, 4])
    classroom_cell_header = make_cell(content: 'Turma', size: 8, font_style: :bold, width: 100, borders: [:top, :left, :right], padding: [2, 2, 4, 4])
    year_cell_header = make_cell(content: 'Ano letivo', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4])
    step_cell_header = make_cell(content: 'Etapa', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4])

    unity_cell = make_cell(content: @unity.name, size: 10, width: 100, borders: [:left, :right], padding: [0, 2, 4, 4], colspan: 2)
    student_cell = make_cell(content: student.name, size: 10, borders: [:left, :right], padding: [0, 2, 4, 4])
    classroom_cell = make_cell(content: @classroom.description, size: 10, borders: [:left, :right], padding: [0, 2, 4, 4])
    year_cell = make_cell(content: @year.to_s, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4])
    step_cell = make_cell(content: @school_calendar_step.to_s, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4])

    identification_table_data = [
      [header_cell],
      [unity_cell_header],
      [unity_cell],
      [student_cell_header, classroom_cell_header],
      [student_cell, classroom_cell],
      [year_cell_header, step_cell_header],
      [year_cell, step_cell]
    ]

    table(identification_table_data, width: bounds.width) do
      cells.border_width = 0.25
      row(0).border_top_width = 0.25
      row(-1).border_bottom_width = 0.25
      column(0).border_left_width = 0.25
      column(-1).border_right_width = 0.25
    end

    move_down GAP
  end

  def disciplines_table(student)
    disciplines = {}
    subheader_cells = []

    Discipline.by_classroom(@classroom.id).ordered.each do |discipline|
      avaliations = Avaliation.by_unity_id(@unity.id)
                              .by_classroom_id(@classroom.id)
                              .by_discipline_id(discipline.id)
                              .by_test_date_between(@school_calendar_step.start_at, @school_calendar_step.end_at)
                              .order(:test_date)
      discipline_scores = []
      avaliations.each do |avaliation|
        student_note = nil

        if exempted_avaliation?(student.id, avaliation.id)
          student_note = "D"
          @show_dispensation = true
        else
          student_notes = [
              DailyNoteStudent.by_avaliation(avaliation.id)
                              .by_student_id(student.id)
                              .first
                              .try(:note),
              AvaliationRecoveryDiaryRecord.by_avaliation_id(avaliation.id)
                              .try(:first)
                              .try(:recovery_diary_record)
                              .try(:students)
                              .try(:by_student_id, student.id)
                              .try(:first)
                              .try(:score)
          ].compact
          student_note = localize_score(student_notes.max)
        end
        discipline_scores << student_note if student_note
      end

      complementary_exams = fetch_complementary_exams(discipline.id)
      complementary_exams.each do |complementary_exam|
        student_score = complementary_exam.students.by_student_id(student.id).first.try(:score)
        discipline_scores << localize_score(student_score) if student_score
      end
      disciplines[discipline.id] = discipline_scores
    end

    number_of_scores = disciplines.map { |_key, hash| hash.length }.max
    number_of_scores = 1 if number_of_scores.nil? || number_of_scores.zero?
    header_cell = make_cell(content: 'Informações gerais', size: 12, font_style: :bold, height: 20, padding: [2, 2, 4, 4], align: :center, colspan: 2 + number_of_scores)
    subheader_cells << make_cell(content: 'Disciplina', align: :left, size: 8, font_style: :bold, width: 156, borders: [:top, :left, :right, :bottom], padding: [2, 2, 4, 4])
    number_of_scores.times do
      subheader_cells << make_cell(content: 'Nota', align: :center, size: 8, font_style: :bold, borders: [:top, :right, :bottom], padding: [2, 2, 4, 4])
    end
    subheader_cells << make_cell(content: 'Faltas', align: :center, size: 8, font_style: :bold, width: 49, borders: [:top, :right, :bottom], padding: [2, 2, 4, 4])

    data = [ subheader_cells ]

    disciplines.each do |discipline_id, scores|
      exempted_from_discipline = exempted_from_discipline?(student.id, discipline_id)
      @show_dispensation = true if exempted_from_discipline
      row = []
      discipline = Discipline.find(discipline_id)
      row << make_cell(content: discipline.to_s, align: :left, size: 10, width: 156, borders: [:left, :right, :bottom], padding: [4, 4, 4, 4])

      number_of_scores.times do |i|
        if exempted_from_discipline
          score = "D"
        else
          score = scores[i] || "-"
        end

        row << make_cell(content: score, align: :left, size: 10, borders: [:right, :bottom], padding: [4, 4, 4, 4])
      end
      row << make_cell(content: absences_count(student.id, discipline.id).to_s, align: :center, size: 10, font_style: :bold, width: 49, borders: [:right, :bottom], padding: [2, 2, 4, 4])

      data << row
    end

    table([[header_cell]], row_colors: ['DEDEDE'], width: bounds.width) do |t|
      t.cells.border_width = 0.25
      t.before_rendering_page do |page|
        page.row(0).border_top_width = 0.25
        page.row(-1).border_bottom_width = 0.25
        page.column(0).border_left_width = 0.25
        page.column(-1).border_right_width = 0.25
      end
    end

    table(data, row_colors: ['FFFFFF', 'DEDEDE'], width: bounds.width) do |t|
      t.cells.border_width = 0.25
      t.before_rendering_page do |page|
        page.row(0).border_top_width = 0.25
        page.row(-1).border_bottom_width = 0.25
        page.column(0).border_left_width = 0.25
        page.column(-1).border_right_width = 0.25
      end
    end

    move_down 50
    text('____________________________', size: 8, align: :center)
    text('Secretário(a) escolar', size: 10, align: :center)
  end

  def body
    page_content do
      @students.each_with_index do |student, index|
        identification(student)
        disciplines_table(student)

        start_new_page if index != @students.size - 1
      end
    end
  end

  def footer
    page_footer(draw_datetime: true) do
      repeat(:all) do
        draw_text('Legendas: D - Dispensado da avaliação ou disciplina', size: 8, at: [0, 15]) if @show_dispensation
      end
    end
  end

  def localize_score(value)
    return value unless value.is_a? Numeric
    number_with_precision(value, precision: @test_setting.number_of_decimal_places||1)
  end

  def absences_count(student_id, discipline_id)
    if @classroom.exam_rule.frequency_type == "2"
      DailyFrequencyStudent.general_by_classroom_discipline_student_date_between(
        @classroom.id, discipline_id, student_id, @school_calendar_step.start_at, @school_calendar_step.end_at
      ).absences.count
    else
      @global_absences_count ||= DailyFrequencyStudent.general_by_classroom_student_date_between(
        @classroom.id, student_id, @school_calendar_step.start_at, @school_calendar_step.end_at
      ).absences.count
    end
  end

  def exempted_avaliation?(student_id, avaliation_id)
    AvaliationExemption.by_student(student_id)
                       .by_avaliation(avaliation_id)
                       .any?
  end

  def student_enrollment(student_id)
    @student_enrollment ||= StudentEnrollment.by_student(student_id)
                                             .by_date_range(@school_calendar_step.start_at, @school_calendar_step.end_at)
                                             .first
  end

  def exempted_from_discipline?(student_id, discipline_id)
    return false unless student_enrollment(student_id)
    step_number = @school_calendar_step.to_number

    student_enrollment(student_id).exempted_disciplines.by_discipline(discipline_id)
                                                       .by_step_number(step_number)
                                                       .any?
  end

  def fetch_complementary_exams(discipline_id)
    complementary_exams = ComplementaryExam.by_unity_id(@unity.id)
                              .by_classroom_id(@classroom.id)
                              .by_discipline_id(discipline_id)
                              .by_date_range(@school_calendar_step.start_at, @school_calendar_step.end_at)
                              .ordered
  end
end
