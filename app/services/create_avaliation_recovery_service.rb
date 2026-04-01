# frozen_string_literal: true

# Service para criar recuperação de avaliação automaticamente
class CreateAvaliationRecoveryService
  def initialize(avaliation)
    @avaliation = avaliation
  end

  def call
    return false unless should_create?

    recovery_diary_record = build_recovery_diary_record
    avaliation_recovery = build_avaliation_recovery(recovery_diary_record)

    avaliation_recovery.save
  end

  private

  def should_create?
    @avaliation.should_create_recovery &&
      @avaliation.avaliation_recovery_diary_record.blank? &&
      daily_note.present? &&
      daily_note.students.any?
  end

  def daily_note
    @daily_note ||= DailyNote.find_by(avaliation_id: @avaliation.id)
  end

  def build_recovery_diary_record
    recovery_diary_record = initialize_recovery_diary_record
    populate_students(recovery_diary_record)
    recovery_diary_record
  end

  def initialize_recovery_diary_record
    recovery_record = RecoveryDiaryRecord.new(
      unity: @avaliation.unity,
      classroom: @avaliation.classroom,
      discipline: @avaliation.discipline,
      recorded_at: parse_date(@avaliation.test_date)
    )
    recovery_record.teacher_id = find_teacher_id
    recovery_record
  end

  def populate_students(recovery_diary_record)
    fetch_student_enrollments.each do |student_enrollment|
      recovery_diary_record.students.build(
        student_id: student_enrollment.student_id
      )
    end
  end

  def build_avaliation_recovery(recovery_diary_record)
    AvaliationRecoveryDiaryRecord.new(
      avaliation: @avaliation,
      recovery_diary_record: recovery_diary_record
    )
  end

  def fetch_student_enrollments
    return [] if @avaliation.grade_ids.blank?

    StudentEnrollmentsList.new(
      classroom: @avaliation.classroom,
      grade: @avaliation.grade_ids,
      discipline: @avaliation.discipline,
      date: @avaliation.test_date,
      score_type: StudentEnrollmentScoreTypeFilters::NUMERIC,
      search_type: :by_date
    ).student_enrollments
  rescue StandardError => e
    Rails.logger.error("Erro ao buscar alunos para recuperação: #{e.message}")
    []
  end

  def find_teacher_id
    # Busca o teacher_id através do relacionamento TeacherDisciplineClassroom
    teacher_discipline_classroom = TeacherDisciplineClassroom.find_by(
      classroom_id: @avaliation.classroom_id,
      discipline_id: @avaliation.discipline_id,
      active: true
    )

    teacher_discipline_classroom&.teacher_id
  end

  def parse_date(date)
    return date if date.is_a?(Date)
    return Date.parse(date) if date.is_a?(String)
    date
  end
end
