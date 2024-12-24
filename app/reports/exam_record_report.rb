require 'action_view'

class ExamRecordReport < BaseReport
  include ActionView::Helpers::NumberHelper

  # This number represent how many students are printed on each page
  STUDENT_BY_PAGE_COUNT = 25

  # This factor represent the quantitty of students with social name needed to reduce 1 student by page
  SOCIAL_NAME_REDUCTION_FACTOR = 3

  def self.build(
    entity_configuration,
    teacher,
    year,
    school_calendar_step,
    test_setting,
    daily_notes,
    info_students,
    complementary_exams,
    school_term_recoveries,
    recovery_lowest_notes,
    lowest_notes
  )
    new(:landscape).build(
      entity_configuration,
      teacher,
      year,
      school_calendar_step,
      test_setting,
      daily_notes,
      info_students,
      complementary_exams,
      school_term_recoveries,
      recovery_lowest_notes,
      lowest_notes
    )
  end

  def build(
    entity_configuration,
    teacher,
    year,
    school_calendar_step,
    test_setting,
    daily_notes,
    info_students,
    complementary_exams,
    school_term_recoveries,
    recovery_lowest_notes,
    lowest_notes
  )
    @entity_configuration = entity_configuration
    @teacher = teacher
    @year = year
    @school_calendar_step = school_calendar_step
    @test_setting = test_setting
    @daily_notes = daily_notes
    @info_students = info_students
    @complementary_exams = complementary_exams
    @school_term_recoveries = school_term_recoveries
    @recovery_lowest_notes = recovery_lowest_notes
    @active_search = false
    @lowest_notes = lowest_notes

    header
    content
    footer

    self
  end

  protected

  attr_accessor :any_student_with_dependence

  private

  def student_enrolled_on_date?(student_enrollment, date)
    ActiveStudentsOnDate.call(
      student_enrollments: student_enrollment, date: date
    )
  end

  def classroom
    @classroom ||= @daily_notes.first.classroom
  end

  def discipline
    @discipline ||= @daily_notes.first.discipline
  end

  def header
    exam_header = make_cell(content: 'Registro de avaliações', size: 12, font_style: :bold, background_color: 'DEDEDE', height: 20, padding: [2, 2, 4, 4], align: :center, colspan: 5)
    begin
      logo_cell = make_cell(image: open(@entity_configuration.logo.url), fit: [50, 50], width: 70, rowspan: 4, position: :center, vposition: :center)
    rescue
      logo_cell = make_cell(content: '', width: 70, rowspan: 4)
    end

    entity_name = @entity_configuration ? @entity_configuration.entity_name : ''
    organ_name = @entity_configuration ? @entity_configuration.organ_name : ''

    entity_organ_and_unity_cell = make_cell(content: "#{entity_name}\n#{organ_name}\n#{@daily_notes.first.unity.name}", size: 12, leading: 1.5, align: :center, valign: :center, rowspan: 4, padding: [6, 2, 8, 2])
    classroom_header = make_cell(content: 'Turma', size: 8, font_style: :bold, width: 100, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    year_header = make_cell(content: 'Ano letivo', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    step_header = make_cell(content: 'Etapa', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    discipline_header = make_cell(content: 'Disciplina', size: 8, font_style: :bold, width: 200, colspan: 2, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    teacher_header = make_cell(content: 'Professor', size: 8, font_style: :bold, width: 200, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    classroom_cell = make_cell(content: classroom.description, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)
    year_cell = make_cell(content: @year.to_s, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)
    step_cell = make_cell(content: @school_calendar_step.to_s, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)
    discipline_cell = make_cell(content: (discipline ? discipline.description : 'Geral'), size: 10, colspan: 2, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)
    teacher_cell = make_cell(content: @teacher.name, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)

    first_table_data = [[exam_header],
                        [logo_cell, entity_organ_and_unity_cell, classroom_header, year_header, step_header],
                        [classroom_cell, year_cell, step_cell],
                        [discipline_header, teacher_header],
                        [discipline_cell, teacher_cell]]

    page_header do
      table(first_table_data, width: bounds.width, header: true) do
        cells.border_width = 0.25
        row(0).border_top_width = 0.25
        row(-1).border_bottom_width = 0.25
        column(0).border_left_width = 0.25
        column(-1).border_right_width = 0.25
      end
    end
  end

  def daily_notes_table
    school_term_recovery_scores = {}
    self.any_student_with_dependence = false

    calculate_student_averages_and_recovery_notes
    collect_exams_and_recoveries
    collect_exams_and_complementary_exams

    @school_term_recoveries.each do |school_term_recovery|
      @exams << school_term_recovery
    end

    @exams.to_a
    sliced_exams = @exams.each_slice(10).to_a
    pos = 0

    sliced_exams.each_with_index do |daily_notes_slice, index|
      avaliations = []
      students = {}

      daily_notes_slice.each do |exam|
        student_enrollments_exempts = exempted_from_discipline?(exam)

        if recovery_record(exam)
          avaliation_id = @recoveries_avaliation_id[pos]
          daily_note_id = @recoveries_ids[pos]
          pos += 1
        elsif complementary_exam_record(exam)
          avaliation_id = nil
          daily_note_id = nil
        elsif school_term_recovery_record(exam)
          avaliation_id = nil
          daily_note_id = nil
        else
          avaliation_id = exam.avaliation_id
          daily_note_id = exam.id
        end

        avaliations << make_cell(content: exam_description(exam), font_style: :bold, background_color: 'FFFFFF', align: :center, width: 55)

        @info_students.each do |info_students|
          student = info_students[:student]
          student_enrollment = info_students[:student_enrollment]
          student_enrollment_classroom = info_students[:student_enrollment_classroom]
          exempted_from_discipline = student_enrollments_exempts[student_enrollment.id]
          in_active_search = ActiveSearch.new.in_active_search?(student_enrollment.id, exam.test_date)
          student_classroom_left_at = student_enrollment_classroom.left_at
          daily_note_student = nil

          if exempted_from_discipline || (avaliation_id.present? && exempted_avaliation?(student.id, avaliation_id))
            student_note = ExemptedDailyNoteStudent.new
            @averages[student_enrollment.id] = "D" if exempted_from_discipline
          elsif in_active_search
            @active_search = true
            student_note = ActiveSearchDailyNoteStudent.new
          elsif avaliation_id.present?
            note_student = DailyNoteStudent.find_by(student_id: student.id, daily_note_id: daily_note_id, active: true)
            daily_note_student = student_transferred?(note_student) if note_student.present?
            student_note = daily_note_student || NullDailyNoteStudent.new
          end

          score = nil

          if exempted_from_discipline || avaliation_id.present?
            @averages[student_enrollment.id] = nil if exempted_from_discipline

            score = set_student_score(exam, student, student_note, student_enrollment, daily_note_student)
          elsif complementary_exam_record(exam)
            complementary_student = ComplementaryExamStudent.find_by(complementary_exam_id: exam.id, student_id: student.id)
            score = complementary_student.present? ? complementary_student.try(:score) : NullDailyNoteStudent.new.note
          elsif school_term_recovery_record(exam)
            recovery_student = RecoveryDiaryRecordStudent.find_by(student_id: student.id, recovery_diary_record_id: exam.recovery_diary_record_id)
            score = recovery_student.present? ? recovery_student.try(:score) : (student_enrolled_on_date?(student_enrollment, exam.recorded_at) ? '' :NullDailyNoteStudent.new.note)
            school_term_recovery_scores[student_enrollment.id] = recovery_student.try(:score)
          end

          if score.nil? && student_classroom_left_at != "" && student_classroom_left_at.to_date <= exam.test_date
            score = set_student_score(exam, student, NullDailyNoteStudent.new, student_enrollment, daily_note_student)
          end

          self.any_student_with_dependence = any_student_with_dependence || student_has_dependence?(student_enrollment, exam.discipline_id)

          (students[student_enrollment.id] ||= {})[:name] = student.to_s

          students[student_enrollment.id] = {} if students[student_enrollment.id].nil?
          students[student_enrollment.id][:dependence] = students[student_enrollment.id][:dependence] || student_has_dependence?(student_enrollment, exam.discipline_id)
          (students[student_enrollment.id][:scores] ||= []) << make_cell(content: localize_score(score), align: :center)
          students[student_enrollment.id][:social_name] = student.social_name
          students[student_enrollment.id][:student_id] = student.id
        end
      end

      sequential_number_header = make_cell(content: 'Nº', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center, width: 15)
      student_name_header = make_cell(content: 'Nome do aluno', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center, width: 170)
      average_header = make_cell(content: "Média", size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center, width: 30)

      first_headers_and_cells = [sequential_number_header, student_name_header].concat(avaliations)

      if @recovery_lowest_notes
        lowest_note_header = make_cell(content: "Rec. geral", size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center, width: 30)
        first_headers_and_cells << lowest_note_header
      end

      (10 - avaliations.count).times { first_headers_and_cells << make_cell(content: '', background_color: 'FFFFFF', width: 55) }
      first_headers_and_cells << average_header

      students_cells = []
      students = students.sort_by { |(key, value)| value[:dependence] ? 1 : 0 }
      sequence = 1
      sequence_reseted = false
      students.each do |key, value|
        if !sequence_reseted && value[:dependence]
          sequence = 1
          sequence_reseted = true
        end

        sequence_cell = make_cell(content: sequence.to_s, align: :center)
        student_cells = [sequence_cell, { content: (value[:dependence] ? '* ' : '') + value[:name] }].concat(value[:scores])
        data_column_count = value[:scores].count + (value[:recoveries].nil? ? 0 : value[:recoveries].count)

        if @recovery_lowest_notes
          student_cells << make_cell(content: "#{@recovery_lowest_note[key]}", align: :center)
        end

        number_colums = 10

        (number_colums - data_column_count).times { student_cells << nil }

        if daily_notes_slice == sliced_exams.last
          recovery_score = if school_term_recovery_scores[key]
                             calculate_recovery_score(value[:student_id], school_term_recovery_scores[key])
                           end

          recovery_average = SchoolTermAverageCalculator.new(classroom)
                                                        .calculate(@averages[key], recovery_score)
          @averages[key] = ScoreRounder.new(classroom, RoundedAvaliations::SCHOOL_TERM_RECOVERY, @school_calendar_step)
                                      .round(recovery_average)

          average = @averages[key]
          student_cells << make_cell(content: "#{average}", font_style: :bold, align: :center)
        else
          student_cells << make_cell(content: '-', font_style: :bold, align: :center)
        end
        students_cells << student_cells

        sequence += 1
      end

      (10 - students_cells.count).times do
        sequence_cell = make_cell(content: (students_cells.count + 1).to_s, align: :center)
        scores = []
        10.times { scores << make_cell(content: '', align: :center) }
        student_cells = [sequence_cell, { content: '' }].concat(scores)
        student_cells << make_cell(content: '', align: :center)
        students_cells << student_cells
      end

      sliced_students_cells = students_cells.each_slice(student_slice_size(students)).to_a

      sliced_students_cells.each_with_index do |students_cells_slice, index|
        data = [
          first_headers_and_cells
        ]
        data.concat(students_cells_slice)

        page_content do
          table(data,
            row_colors: ['FFFFFF', 'DEDEDE'],
            cell_style: { size: 8, padding: [2, 2, 2, 2], inline_format: true },
            width: bounds.width
          ) do |t|
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

      start_new_page if index < sliced_exams.count - 1
    end
  end

  def set_student_score(exam, student, student_note, student_enrollment, daily_note_student)
    recovery_note = find_recovery_note_if_needed(exam, student)
    student_note.recovery_note = recovery_note if recovery_note.present? && daily_note_student.blank?

    determine_score(student_note, exam, student_enrollment)
  end

  def find_recovery_note_if_needed(exam, student)
    return nil unless recovery_record(exam)

    exam.students.find_by_student_id(student.id).try(&:score)
  end

  def determine_score(student_note, exam, student_enrollment)
    return student_note.note unless recovery_record(exam)

    recovery_score = student_note.recovery_note

    return recovery_score if student_enrolled_on_date?(student_enrollment, exam.recorded_at).present?

    NullDailyNoteStudent.new.note
  end

  def calculate_student_averages_and_recovery_notes
    @averages = {}
    @recovery_lowest_note = {}

    @info_students.each do |info_students|
      student = info_students[:student]
      student_enrollment_id = info_students[:student_enrollment].id

      @averages[student_enrollment_id] = StudentAverageCalculator.new(
        student
      ).calculate(
        classroom,
        discipline,
        @school_calendar_step
      )

      next if @lowest_notes.blank?

      lowest_note = @lowest_notes[student.id].to_s

      next if lowest_note.blank?

      @recovery_lowest_note[student_enrollment_id] = lowest_note
    end
  end

  def collect_exams_and_recoveries
    @exams = []
    @recoveries_avaliation_id = []
    @recoveries_ids = []

    @daily_notes.each do |daily_note|
      @exams << daily_note

      next if daily_note.avaliation.recovery_diary_record.blank?

      @exams << daily_note.avaliation.recovery_diary_record
      @recoveries_avaliation_id << daily_note.avaliation_id
      @recoveries_ids << daily_note.id
    end
  end

  def collect_exams_and_complementary_exams
    integral_complementary_exams = []

    @complementary_exams.each do |complementary_exam|
      if complementary_exam.complementary_exam_setting.integral?
        integral_complementary_exams << complementary_exam
        next
      end

      @exams << complementary_exam
    end

    integral_complementary_exams.each do |integral_exam|
      @exams << integral_exam
    end
  end

  def student_transferred?(note_student)
    return note_student unless note_student.transfer_note_id

    return note_student if note_student.note? || note_student.note == 0.0

    nil
  end

  def calculate_recovery_score(student_id, score)
    ComplementaryExamCalculator.new(
      [AffectedScoreTypes::STEP_RECOVERY_SCORE, AffectedScoreTypes::BOTH],
      student_id,
      discipline.id,
      classroom.id,
      @school_calendar_step
    ).calculate(score)
  end

  def student_slice_size(students)
    student_with_social_name_count = students.select { |(key, value)|
      value[:social_name].present?
    }.length

    STUDENT_BY_PAGE_COUNT - (student_with_social_name_count / SOCIAL_NAME_REDUCTION_FACTOR)
  end

  def content
    daily_notes_table
  end

  def footer
    page_footer do
      repeat(:all) do
        draw_text('Assinatura do(a) professor(a):', size: 8, style: :bold, at: [0, 0])
        draw_text('____________________________', size: 8, at: [117, 0])

        draw_text('Assinatura do(a) coordenador(a)/diretor(a):', size: 8, style: :bold, at: [259, 0])
        draw_text('____________________________', size: 8, at: [429, 0])

        draw_text('Data:', size: 8, style: :bold, at: [559, 0])
        draw_text('________________', size: 8, at: [581, 0])
        if @active_search
          draw_text('Legendas: N - Não enturmado, D - Dispensado da avaliação ou da disciplina, B - Busca ativa', size: 8, style: :bold, at: [0, 17])
        else
          draw_text('Legendas: N - Não enturmado, D - Dispensado da avaliação ou da disciplina', size: 8, style: :bold, at: [0, 17])
        end
        draw_text('* Alunos cursando dependência', size: 8, at: [0, 32]) if self.any_student_with_dependence
      end
    end
  end

  def exempted_avaliation?(student_id, avaliation_id)
    avaliation_is_exempted = AvaliationExemption
      .by_student(student_id)
      .by_avaliation(avaliation_id)
      .any?
    avaliation_is_exempted
  end

  def exempted_from_discipline?(exam)
    steps_fetcher = StepsFetcher.new(classroom)
    test_date = exam.test_date
    step_number = steps_fetcher.step_by_date(test_date).to_number

    StudentsExemptFromDiscipline.call(
      student_enrollments: @info_students.map { |info| info[:student_enrollment].id },
      discipline: discipline,
      step: step_number
    )
  end

  def recovery_record(record)
    record.class.to_s == "RecoveryDiaryRecord"
  end

  def complementary_exam_record(record)
    record.class.to_s == "ComplementaryExam"
  end

  def school_term_recovery_record(record)
    record.class.to_s == "SchoolTermRecoveryDiaryRecord"
  end

  def localize_score(value)
    return value unless value.is_a? Numeric
    number_with_precision(value, precision: @test_setting.number_of_decimal_places||1)
  end

  def student_has_dependence?(student_enrollment, discipline)
    StudentEnrollmentDependence
      .by_student_enrollment(student_enrollment)
      .by_discipline(discipline)
      .any?
  end

  def exam_description(record)
    if recovery_record(record)
      "Rec. #{record.avaliation_recovery_diary_record.avaliation}\n<font size='7'>#{record.recorded_at.strftime("%d/%m")}</font>"
    elsif complementary_exam_record(record)
      "#{record.complementary_exam_setting.description}\n<font size='7'>#{record.recorded_at.strftime("%d/%m")}\n#{record.complementary_exam_setting.maximum_score}</font>"
    elsif school_term_recovery_record(record)
      "Recuperação da etapa\n<font size='7'>#{record.recorded_at.strftime("%d/%m")}"
    else
      "#{record.avaliation.to_s}\n<font size='7'>#{record.test_date.strftime("%d/%m")}</font>\n<font size='7'>#{record.avaliation.try(:weight)}</font>"
    end
  end
end
