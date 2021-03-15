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

      daily_notes = DailyNote.by_classroom_id(@classroom.id)
                             .by_discipline_id(@discipline.id)
                             .by_test_date_between(@step.start_at, @step.end_at)
                             .active

      validate_exam_quantity(number_of_exams)
      validate_exam_quantity_for_fix_test(number_of_exams)
      validate_pending_exams(daily_notes, exams)

      student_ids = fetch_student_ids(daily_notes.by_active_student_enrollment_classroom(@classroom.id))
      students = Student.find(student_ids)

      @scores = students.each do |student|
        student_exams = DailyNoteStudent.by_classroom_id(@classroom)
                                        .by_discipline_id(@discipline)
                                        .by_student_id(student.id)
                                        .by_test_date_between(@step.start_at, @step.end_at)
                                        .active

        pending_exams = student_exams.select { |e| e.note.blank? && !e.exempted? }

        if pending_exams.any?
          pending_exams_string = pending_exams.map { |e| e.daily_note.avaliation.description_to_teacher }.join(', ')
          @warning_messages << "O aluno #{student} não possui nota lançada no diário de avaliações numéricas na turma #{@classroom}, disciplina de #{@discipline}. Avaliações: #{pending_exams_string}."
        end
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

    def fetch_student_ids(daily_notes)
      student_ids = []
      daily_notes.each { |d| student_ids << d.students.map(&:student_id) }
      student_ids.flatten!.uniq! if student_ids.any?
      student_ids
    end

    def current_test_setting
      TestSettingFetcher.current(@classroom, @step)
    end
  end
end
