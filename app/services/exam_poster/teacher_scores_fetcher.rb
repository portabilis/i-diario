module ExamPoster
  class TeacherScoresFetcher
    attr_reader :scores
    attr_reader :warning_messages

    def initialize(teacher, classroom, discipline, step)
      @teacher = teacher
      @classroom = classroom
      @discipline = discipline
      @step = step
      @warning_messages = []
      @scores = []
    end

    def fetch!
      exams = Avaliation.by_classroom_id(@classroom.id)
                        .by_discipline_id(@discipline.id)
                        .by_test_date_between(@step.start_at, @step.end_at)
      number_of_exams = exams.count

      daily_notes = DailyNote.includes(:students)
                             .by_classroom_id(@classroom.id)
                             .by_discipline_id(@discipline.id)
                             .by_test_date_between(@step.start_at, @step.end_at)
                             .active

      validate_exam_quantity(number_of_exams)
      validate_exam_quantity_for_fix_test(number_of_exams)
      validate_pending_exams(daily_notes, exams)

      students = fetch_student(daily_notes, exams)

      daily_note_students = DailyNoteStudent.includes(:student)
                                            .by_classroom_id(@classroom)
                                            .by_discipline_id(@discipline)
                                            .where(student: students)
                                            .by_test_date_between(@step.start_at, @step.end_at)
                                            .active
      student_scores = {}

      @scores = daily_note_students.map do |dns|
        pending_exam = dns if dns.note.blank? && !dns.exempted?

        if pending_exam.present?
          pending_exam_string = pending_exam.daily_note.avaliation.description_to_teacher
          student_scores[dns.student] ||= []
          student_scores[dns.student] << pending_exam_string
        end

        dns.student
      end.uniq

      student_scores.each do |student, pending_exams|
        pending_exams_string = pending_exams.join(', ')
        @warning_messages << "O aluno #{student} não possui nota lançada no diário de avaliações numéricas na turma #{@classroom}, disciplina de #{@discipline}. Avaliações: #{pending_exams_string}."
      end
    end

    def warnings?
      @warning_messages.present?
    end

    private

    def validate_exam_quantity(number_of_exams)
      return unless number_of_exams.zero?

      @warning_messages << "Não foi possível enviar as avaliações numéricas da turma #{@classroom} pois não foram cadastradas avaliações numéricas para a disciplina #{@discipline}."
    end

    def validate_exam_quantity_for_fix_test(number_of_exams)
      return unless current_test_setting.present? && current_test_setting.sum_calculation_type?
      return unless number_of_exams < current_test_setting.tests.count

      @warning_messages << "Não foi possível enviar as avaliações numéricas da turma #{@classroom} pois não foram cadastradas todas as avaliações numéricas da configuração de avaliações numéricas para a disciplina #{@discipline}."
    end

    def validate_pending_exams(daily_notes, exams)
      number_of_exams = exams.count

      if daily_notes.count < number_of_exams
        pending_exams = exams.select { |exam| daily_notes.none? { |daily_note| daily_note.avaliation_id == exam.id } }
        pending_exams_string = pending_exams.map(&:description_to_teacher).join(', ')
        @warning_messages << "Não foi possível enviar as avaliações numéricas da turma #{@classroom} pois existem avaliações que não foram lançadas no diário de avaliações numéricas para a disciplina #{@discipline}. Avaliações: #{pending_exams_string}."
      end
    end

    def fetch_student(daily_notes, exams)
      avaliations = exams.pluck(:id, :test_date).to_h
      filter_daily_notes = daily_notes.where(avaliation_id: avaliations.keys)
      daily_note_students = filter_daily_notes.flat_map(&:students)
                                              .select { |dns| dns.transfer_note_id.present? }
      active_enrollment_classrooms = StudentEnrollmentClassroom.by_classroom(@classroom.id).active

      enrollment_classroom_on_date = []

      filter_daily_notes.each do |daily_note|
        avaliation_id = daily_note.avaliation_id
        date_avaliation = avaliations[avaliation_id].to_date

        enrollment_classroom_on_date += active_enrollment_classrooms.select do |sec|
          left_at = sec.left_at&.to_date || Date.current

          date_avaliation >= sec.joined_at.to_date && date_avaliation < left_at
        end
      end

      students = Student.joins(student_enrollments: :student_enrollment_classrooms).where(
        student_enrollment_classrooms: {
          id: enrollment_classroom_on_date.flatten.map(&:id)
        }
      )

      students += Student.where(id: daily_note_students.map(&:student_id).uniq)

      students.flatten.uniq
    end

    def current_test_setting
      @current_test_setting ||= TestSettingFetcher.current(@classroom, @step)
    end
  end
end
