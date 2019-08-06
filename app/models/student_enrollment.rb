class StudentEnrollment < ActiveRecord::Base
  include Discardable
  include Audit
  audited
  has_associated_audits

  belongs_to :student

  has_many :student_enrollment_classrooms
  has_many :dependences, class_name: 'StudentEnrollmentDependence'
  has_many :exempted_disciplines, class_name: 'StudentEnrollmentExemptedDiscipline'

  attr_accessor :entity_id

  after_discard { StudentDependenciesDiscarder.discard(entity_id, student_id) }
  after_undiscard { StudentDependenciesDiscarder.undiscard(entity_id, student_id) }

  default_scope -> { kept }

  scope :by_classroom, lambda { |classroom_id| joins(:student_enrollment_classrooms).merge(StudentEnrollmentClassroom.by_classroom(classroom_id)) }
  scope :by_discipline, lambda {|discipline_id| by_discipline_query(discipline_id)}
  scope :by_score_type, lambda {|score_type, classroom_id| by_score_type_query(score_type, classroom_id)}
  scope :by_opinion_type, lambda {|opinion_type, classroom_id| by_opinion_type_query(opinion_type, classroom_id)}
  scope :by_student, lambda { |student_id| where(student_id: student_id) }
  scope :by_year, lambda { |year|
    joins(:student_enrollment_classrooms).merge(StudentEnrollmentClassroom.by_year(year))
  }
  scope :by_date, lambda { |date| joins(:student_enrollment_classrooms).merge(StudentEnrollmentClassroom.by_date(date)) }
  scope :by_date_range, lambda { |start_at, end_at| joins(:student_enrollment_classrooms).merge(StudentEnrollmentClassroom.by_date_range(start_at, end_at)) }
  scope :by_date_not_before, lambda { |date| joins(:student_enrollment_classrooms).merge(StudentEnrollmentClassroom.by_date_not_before(date)) }
  scope :by_period, lambda { |period| joins(:student_enrollment_classrooms).merge(StudentEnrollmentClassroom.by_period(period)) }
  scope :show_as_inactive, lambda { joins(:student_enrollment_classrooms).merge(StudentEnrollmentClassroom.show_as_inactive) }
  scope :with_recovery_note_in_step, lambda { |step, discipline_id| with_recovery_note_in_step_query(step, discipline_id) }
  scope :active, -> { where(active: 1) }
  scope :ordered, -> { joins(:student, :student_enrollment_classrooms).order('sequence ASC, students.name ASC') }

  def self.by_discipline_query(discipline_id)
    unless discipline_id.blank?
      where("(not exists(select 1
                           from student_enrollment_dependences
                          where student_enrollment_dependences.student_enrollment_id = student_enrollments.id) OR
                  exists(select 1
                           from student_enrollment_dependences
                          where student_enrollment_dependences.student_enrollment_id = student_enrollments.id and
                                student_enrollment_dependences.discipline_id = ?))", discipline_id)
    end
  end

  def self.with_recovery_note_in_step_query(step, discipline_id)
    joins(:student_enrollment_classrooms).where('
      ( EXISTS(
        SELECT 1
        FROM recovery_diary_records
        JOIN school_term_recovery_diary_records
        ON recovery_diary_records.id = school_term_recovery_diary_records.recovery_diary_record_id
        JOIN recovery_diary_record_students
        ON recovery_diary_record_students.recovery_diary_record_id = recovery_diary_records.id
        WHERE recovery_diary_records.classroom_id = student_enrollment_classrooms.classroom_id
        AND recovery_diary_records.discipline_id = ?
        AND recovery_diary_records.recorded_at BETWEEN ? AND ?
        AND recovery_diary_record_students.student_id = student_enrollments.student_id
        AND recovery_diary_record_students.score IS NOT NULL
      ))
    ', discipline_id, step.start_at, step.end_at)
  end

  def self.by_score_type_query(score_type, classroom_id)
    return where(nil) if score_type == StudentEnrollmentScoreTypeFilters::BOTH
    classroom = Classroom.find(classroom_id)
    exam_rule = classroom.exam_rule

    return where(nil) if exam_rule.blank?

    differentiated_exam_rule = exam_rule.differentiated_exam_rule || exam_rule

    allowed_score_types = [ScoreTypes::NUMERIC_AND_CONCEPT]
    allowed_score_types << (score_type == StudentEnrollmentScoreTypeFilters::CONCEPT ? ScoreTypes::CONCEPT : ScoreTypes::NUMERIC)

    exam_rule_included = allowed_score_types.include?(exam_rule.score_type)
    differentiated_exam_rule_included = allowed_score_types.include?(differentiated_exam_rule.score_type)

    return where(nil) if exam_rule_included && differentiated_exam_rule_included
    return none unless exam_rule_included || differentiated_exam_rule_included
    return joins(:student).where(students: {uses_differentiated_exam_rule: differentiated_exam_rule_included})
  end

  def self.by_opinion_type_query(opinion_type, classroom_id)
    return where(nil) unless opinion_type.present? && classroom_id.present?
    classroom = Classroom.find(classroom_id)
    exam_rule = classroom.exam_rule

    return where(nil) if exam_rule.blank?

    differentiated_exam_rule = exam_rule.differentiated_exam_rule || exam_rule

    exam_rule_included = exam_rule.opinion_type == opinion_type
    differentiated_exam_rule_included = differentiated_exam_rule.opinion_type == opinion_type

    return where(nil) if exam_rule_included && differentiated_exam_rule_included
    return none unless exam_rule_included || differentiated_exam_rule_included
    return joins(:student).where(students: {uses_differentiated_exam_rule: differentiated_exam_rule_included})
  end

  def self.exclude_exempted_disciplines(discipline_id, step_number)
    exempted_discipline_ids = StudentEnrollmentExemptedDiscipline.by_discipline(discipline_id)
                                                                 .by_step_number(step_number)
                                                                 .map(&:student_enrollment_id)
                                                                 .uniq
    where.not(id: exempted_discipline_ids)
  end
end
