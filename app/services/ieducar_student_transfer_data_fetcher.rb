# frozen_string_literal: true

class IeducarStudentTransferDataFetcher
  class StudentNotEnrolledError < StandardError; end

  attr_reader :all_postings_sent

  def initialize(student:, classroom:, transfer_date: nil)
    @student = student
    @classroom = classroom
    @transfer_date = parse_transfer_date(transfer_date)
    @all_postings_sent = true
  end

  def post_to_ieducar!
    unless exam_rule
      Rails.logger.warn(
        "IeducarStudentTransferDataFetcher: classroom #{classroom.id} sem exam_rule - notas e pareceres serão ignorados"
      )
      @all_postings_sent = false
    end

    steps.each do |step|
      next if skip_open_last_step?(step)

      post_numerical_scores_for_step(step)
      post_conceptual_scores_for_step(step)
      post_absences_for_step(step)
      post_descriptive_exams_for_step(step)
    end

    post_final_recovery
  end

  private

  attr_reader :student, :classroom, :transfer_date

  # Turmas sem nota (ex.: progressão continuada, com apuração apenas por
  # frequência) são aprovadas no i-Educar assim que ele recebe a frequência da
  # última etapa. Numa transferência ocorrida antes do encerramento dessa etapa,
  # enviar a etapa parcial aprovaria o aluno indevidamente. Por isso, para essas
  # turmas, quando a última etapa ainda está aberta na data da transferência ela
  # é pulada por completo (não só a frequência: também eventuais pareceres da
  # etapa e o parecer anual, que só é postado na última etapa). As demais etapas
  # continuam sendo enviadas normalmente.
  #
  # Fronteira: a etapa é considerada encerrada quando a data de transferência é
  # igual ou posterior ao seu `end_at` (`transfer_date < end_at` => ainda aberta).
  def skip_open_last_step?(step)
    return false unless without_score_exam_rule?
    return false unless step == steps.last

    last_step_open_on_transfer_date?(step)
  end

  def without_score_exam_rule?
    exam_rule&.score_type == ScoreTypes::DONT_USE
  end

  def last_step_open_on_transfer_date?(step)
    return false if transfer_date.blank? || step.end_at.blank?

    transfer_date < step.end_at.to_date
  end

  def parse_transfer_date(value)
    return value if value.is_a?(Date)
    return if value.blank?

    # Parse estrito ISO-8601: o controller já valida o formato antes de
    # enfileirar, então uma string inesperada aqui é estado anômalo.
    Date.iso8601(value.to_s)
  rescue ArgumentError, TypeError => e
    # Não silenciar: cair aqui desabilita o filtro da última etapa (envia tudo),
    # que é justamente a proteção deste fluxo. Notificamos o Honeybadger com
    # contexto e seguimos sem filtrar para não derrubar o restante do envio.
    Rails.logger.error(
      "IeducarStudentTransferDataFetcher: transfer_date inválida (#{value.inspect}) " \
      "student=#{student&.id} classroom=#{classroom&.id} - última etapa não será filtrada"
    )
    Honeybadger.notify(
      e,
      context: { student_id: student&.id, classroom_id: classroom&.id, transfer_date: value }
    )
    nil
  end

  def steps
    @steps ||= StepsFetcher.new(classroom).steps
  end

  def disciplines
    @disciplines ||= classroom.disciplines
  end

  def school_calendar
    @school_calendar ||= StepsFetcher.new(classroom).school_calendar
  end

  def ieducar_api
    @ieducar_api ||= IeducarApiConfiguration.current
  end

  def absence_count_service
    @absence_count_service ||= AbsenceCountService.new(
      GeneralConfiguration.current.do_not_send_justified_absence
    )
  end

  def exam_rule
    @exam_rule ||= begin
      rule = student_classrooms_grade&.exam_rule || classroom.first_exam_rule
      if student.uses_differentiated_exam_rule && rule&.differentiated_exam_rule.present?
        rule.differentiated_exam_rule
      else
        rule
      end
    end
  end

  def student_classrooms_grade
    @student_classrooms_grade ||= StudentEnrollmentClassroom
      .joins(:student_enrollment, :classrooms_grade)
      .where(student_enrollments: { student_id: student.id })
      .where(classrooms_grades: { classroom_id: classroom.id })
      .where("COALESCE(student_enrollment_classrooms.left_at, '') = ''")
      .first
      &.classrooms_grade
  end

  def frequency_by_discipline?
    exam_rule&.frequency_type == FrequencyTypes::BY_DISCIPLINE
  end

  # Numerical scores
  def post_numerical_scores_for_step(step)
    return unless numerical_score_type?

    disciplines.each do |discipline|
      next if exempted_discipline?(discipline, step)

      value = StudentAverageCalculator.new(student).calculate(classroom, discipline, step)
      next if value.blank?

      score_data = { 'nota' => value }

      recovery_value = fetch_school_term_recovery_score(discipline, step)
      score_data['recuperacao'] = recovery_value if recovery_value.present?

      send_score_to_ieducar(step, discipline, score_data, ApiPostingTypes::NUMERICAL_EXAM)
    end
  end

  def fetch_school_term_recovery_score(discipline, step)
    school_term_recovery = SchoolTermRecoveryDiaryRecord
                           .by_classroom_id(classroom)
                           .by_discipline_id(discipline)
                           .by_step_id(classroom, step.id)
                           .first

    return unless school_term_recovery

    recovery_student = school_term_recovery.recovery_diary_record
                                           .students
                                           .find_by(student_id: student.id)

    return unless recovery_student&.score.present?

    adjusted_score = ComplementaryExamCalculator.new(
      [AffectedScoreTypes::STEP_RECOVERY_SCORE, AffectedScoreTypes::BOTH],
      student,
      discipline.id,
      classroom.id,
      step
    ).calculate(recovery_student.score)

    ScoreRounder.new(
      classroom,
      RoundedAvaliations::SCHOOL_TERM_RECOVERY,
      step
    ).round(adjusted_score)
  end

  def send_score_to_ieducar(step, discipline, score_data, post_type)
    params = {
      etapa: step.to_number,
      resource: 'notas',
      notas: {
        classroom.api_code => {
          student.api_code => {
            discipline.api_code => score_data
          }
        }
      }
    }

    send_to_ieducar(post_type, params)
  end

  # Conceptual scores
  def post_conceptual_scores_for_step(step)
    return unless conceptual_score_type?

    conceptual_exam = ConceptualExam
                      .by_classroom(classroom)
                      .by_student_id(student.id)
                      .by_step_id(classroom, step.id)
                      .first

    return unless conceptual_exam

    conceptual_exam.conceptual_exam_values.each do |exam_value|
      next if exam_value.value.blank?
      next if exempted_discipline?(exam_value.discipline, step)

      score_data = { 'nota' => exam_value.value }
      send_score_to_ieducar(step, exam_value.discipline, score_data, ApiPostingTypes::CONCEPTUAL_EXAM)
    end
  end

  # Absences
  def post_absences_for_step(step)
    if frequency_by_discipline?
      post_absences_by_discipline_for_step(step)
    else
      post_general_absences_for_step(step)
    end
  end

  def post_general_absences_for_step(step)
    value = absence_count_service.count(student, classroom, step.start_at, step.end_at)

    params = {
      etapa: step.to_number,
      resource: 'faltas-geral',
      faltas: {
        classroom.api_code => {
          student.api_code => { 'valor' => value }
        }
      }
    }

    send_to_ieducar(ApiPostingTypes::ABSENCE, params)
  end

  def post_absences_by_discipline_for_step(step)
    disciplines.each do |discipline|
      value = absence_count_service.count(student, classroom, step.start_at, step.end_at, discipline)

      knowledge_area = discipline.grouper? ? discipline.knowledge_area&.api_code.to_i : nil
      knowledge_area = nil if knowledge_area&.zero?

      params = {
        etapa: step.to_number,
        resource: 'faltas-por-componente',
        faltas: {
          classroom.api_code => {
            student.api_code => {
              discipline.api_code => {
                'valor' => value,
                'area_do_conhecimento' => knowledge_area
              }
            }
          }
        }
      }

      send_to_ieducar(ApiPostingTypes::ABSENCE, params)
    end
  end

  # Descriptive exams
  def post_descriptive_exams_for_step(step)
    opinion_type = exam_rule&.opinion_type

    case opinion_type
    when OpinionTypes::BY_STEP
      post_descriptive_by_step(step)
    when OpinionTypes::BY_STEP_AND_DISCIPLINE
      post_descriptive_by_step_and_discipline(step)
    when OpinionTypes::BY_YEAR
      post_descriptive_by_year if step == steps.last
    when OpinionTypes::BY_YEAR_AND_DISCIPLINE
      post_descriptive_by_year_and_discipline if step == steps.last
    end
  end

  def post_descriptive_by_step(step)
    exam = DescriptiveExamStudent
           .joins(:descriptive_exam)
           .by_student_id(student.id)
           .merge(DescriptiveExam.by_classroom_id(classroom.id).by_step_id(classroom, step.id))
           .where(descriptive_exams: { discipline_id: nil })
           .first

    return unless exam&.value.present?

    params = {
      etapa: step.to_number,
      resource: 'pareceres-por-etapa-geral',
      pareceres: {
        classroom.api_code => {
          student.api_code => { 'valor' => exam.value }
        }
      }
    }

    send_to_ieducar(ApiPostingTypes::DESCRIPTIVE_EXAM, params)
  end

  def post_descriptive_by_step_and_discipline(step)
    disciplines.each do |discipline|
      next if exempted_discipline?(discipline, step)

      exam = DescriptiveExamStudent
             .joins(:descriptive_exam)
             .by_student_id(student.id)
             .merge(
               DescriptiveExam.by_classroom_id(classroom.id)
                              .by_discipline_id(discipline.id)
                              .by_step_id(classroom, step.id)
             )
             .first

      next unless exam&.value.present?

      params = {
        etapa: step.to_number,
        resource: 'pareceres-por-etapa-e-componente',
        pareceres: {
          classroom.api_code => {
            student.api_code => {
              discipline.api_code => { 'valor' => exam.value }
            }
          }
        }
      }

      send_to_ieducar(ApiPostingTypes::DESCRIPTIVE_EXAM, params)
    end
  end

  def post_descriptive_by_year
    exam = DescriptiveExamStudent
           .joins(:descriptive_exam)
           .by_student_id(student.id)
           .merge(DescriptiveExam.by_classroom_id(classroom.id))
           .where(descriptive_exams: { discipline_id: nil })
           .first

    return unless exam&.value.present?

    params = {
      resource: 'pareceres-anual-geral',
      pareceres: {
        classroom.api_code => {
          student.api_code => { 'valor' => exam.value }
        }
      }
    }

    send_to_ieducar(ApiPostingTypes::DESCRIPTIVE_EXAM, params)
  end

  def post_descriptive_by_year_and_discipline
    disciplines.each do |discipline|
      exam = DescriptiveExamStudent
             .joins(:descriptive_exam)
             .by_student_id(student.id)
             .merge(
               DescriptiveExam.by_classroom_id(classroom.id)
                              .by_discipline_id(discipline.id)
             )
             .first

      next unless exam&.value.present?

      params = {
        resource: 'pareceres-anual-por-componente',
        pareceres: {
          classroom.api_code => {
            student.api_code => {
              discipline.api_code => { 'valor' => exam.value }
            }
          }
        }
      }

      send_to_ieducar(ApiPostingTypes::DESCRIPTIVE_EXAM, params)
    end
  end

  # Final recovery
  def post_final_recovery
    return unless numerical_score_type?

    disciplines.each do |discipline|
      final_recovery = FinalRecoveryDiaryRecord
                       .by_school_calendar_id(school_calendar&.id)
                       .by_classroom_id(classroom.id)
                       .by_discipline_id(discipline.id)
                       .first

      next unless final_recovery

      recovery_student = final_recovery.recovery_diary_record
                                       .students
                                       .find_by(student_id: student.id)

      next unless recovery_student&.score.present?

      step = steps.last
      score_rounder = ScoreRounder.new(
        classroom,
        RoundedAvaliations::FINAL_RECOVERY,
        step
      )

      value = score_rounder.round(recovery_student.score)
      next if value.blank?

      params = {
        notas: {
          classroom.api_code => {
            student.api_code => {
              discipline.api_code => { 'nota' => value }
            }
          }
        }
      }

      send_final_recovery_to_ieducar(params)
    end
  end

  def numerical_score_type?
    [ScoreTypes::NUMERIC, ScoreTypes::NUMERIC_AND_CONCEPT].include?(exam_rule&.score_type)
  end

  def conceptual_score_type?
    [ScoreTypes::CONCEPT, ScoreTypes::NUMERIC_AND_CONCEPT].include?(exam_rule&.score_type)
  end

  def exempted_discipline?(discipline, step)
    ExemptedDisciplinesInStep.discipline_ids(classroom.id, step.to_number).include?(discipline.id)
  end

  def send_to_ieducar(post_type, params)
    api_class = case post_type
                when ApiPostingTypes::NUMERICAL_EXAM, ApiPostingTypes::CONCEPTUAL_EXAM
                  IeducarApi::PostExams
                when ApiPostingTypes::ABSENCE
                  IeducarApi::PostAbsences
                when ApiPostingTypes::DESCRIPTIVE_EXAM
                  IeducarApi::PostDescriptiveExams
    end

    api = api_class.new(ieducar_api.to_api)
    response = IeducarResponseDecorator.new(api.send_post(params))
    @all_postings_sent = false if response.any_error_message?
  end

  def send_final_recovery_to_ieducar(params)
    api = IeducarApi::FinalRecoveries.new(ieducar_api.to_api)
    response = IeducarResponseDecorator.new(api.send_post(params))
    @all_postings_sent = false if response.any_error_message?
  end
end
