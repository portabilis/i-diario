class StudentEnrollment < ActiveRecord::Base
  belongs_to :student

  has_many :student_enrollment_classrooms
  has_many :dependences, class_name: 'StudentEnrollmentDependence'
  has_many :exempted_disciplines, class_name: 'StudentEnrollmentExemptedDiscipline'

  scope :by_classroom, lambda { |classroom_id| joins(:student_enrollment_classrooms).merge(StudentEnrollmentClassroom.by_classroom(classroom_id)) }
  scope :by_discipline, lambda {|discipline_id| by_discipline_query(discipline_id)}
  scope :by_score_type, lambda {|score_type, classroom_id| by_score_type_query(score_type, classroom_id)}
  scope :by_opinion_type, lambda {|opinion_type, classroom_id| by_opinion_type_query(opinion_type, classroom_id)}
  scope :by_student, lambda { |student_id| where(student_id: student_id) }
  scope :by_date, lambda { |date| joins(:student_enrollment_classrooms).merge(StudentEnrollmentClassroom.by_date(date)) }
  scope :by_date_range, lambda { |start_at, end_at| joins(:student_enrollment_classrooms).merge(StudentEnrollmentClassroom.by_date_range(start_at, end_at)) }
  scope :by_date_not_before, lambda { |date| joins(:student_enrollment_classrooms).merge(StudentEnrollmentClassroom.by_date_not_before(date)) }
  scope :exclude_exempted_disciplines, lambda { |discipline_id, step_number| exclude_exempted_disciplines(discipline_id, step_number) }
  scope :show_as_inactive, lambda { joins(:student_enrollment_classrooms).merge(StudentEnrollmentClassroom.show_as_inactive) }
  scope :active, -> { where(active: 1) }
  scope :ordered, -> { joins(:student, :student_enrollment_classrooms).order('sequence ASC, students.name ASC') }

  def self.by_discipline_query(discipline_id)
    unless discipline_id.blank?
      joins("LEFT JOIN student_enrollment_dependences on(student_enrollment_dependences.student_enrollment_id = student_enrollments.id)")
      .where("(student_enrollment_dependences.discipline_id = ? OR student_enrollment_dependences.discipline_id is null)", discipline_id)
    end
  end

  def self.by_score_type_query(score_type, classroom_id)
    return where(nil) if score_type == 'both'
    classroom = Classroom.find(classroom_id)
    exam_rule = classroom.exam_rule
    differentiated_exam_rule = exam_rule.differentiated_exam_rule || exam_rule

    allowed_score_types = [ScoreTypes::NUMERIC_AND_CONCEPT]
    allowed_score_types << (score_type == 'concept' ? ScoreTypes::CONCEPT : ScoreTypes::NUMERIC)

    exam_rule_included = allowed_score_types.include?(exam_rule.score_type)
    differentiated_exam_rule_included = allowed_score_types.include?(differentiated_exam_rule.score_type)

    return where(nil) if exam_rule_included && differentiated_exam_rule_included
    return where('1=2') unless exam_rule_included || differentiated_exam_rule_included
    return joins(:student).where(students: {uses_differentiated_exam_rule: differentiated_exam_rule_included})
  end

  def self.by_opinion_type_query(opinion_type, classroom_id)
    return where(nil) unless opinion_type.present? && classroom_id.present?
    classroom = Classroom.find(classroom_id)
    exam_rule = classroom.exam_rule
    differentiated_exam_rule = exam_rule.differentiated_exam_rule || exam_rule

    exam_rule_included = exam_rule.opinion_type == opinion_type
    differentiated_exam_rule_included = differentiated_exam_rule.opinion_type == opinion_type

    return where(nil) if exam_rule_included && differentiated_exam_rule_included
    return where('1=2') unless exam_rule_included || differentiated_exam_rule_included
    return joins(:student).where(students: {uses_differentiated_exam_rule: differentiated_exam_rule_included})
  end

  def self.exclude_exempted_disciplines(discipline_id, step_number)
    exempted_discipline_ids = StudentEnrollmentExemptedDiscipline.where(discipline_id: discipline_id)
                                                                 .where("? = ANY(string_to_array(steps, ',')::integer[])", step_number)
                                                                 .map(&:student_enrollment_id)
                                                                 .uniq
    where.not(id: exempted_discipline_ids)
  end
end
