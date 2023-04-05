class ComplementaryExamSetting < ApplicationRecord
  acts_as_copy_target

  audited
  has_associated_audits

  include Audit

  validates :description, presence: true
  validates :initials, presence: true
  validates :affected_score, presence: true
  validates :calculation_type, presence: true
  validates :grade_ids, presence: true
  validates :maximum_score, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 1000 }
  validates :number_of_decimal_places, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 3 }
  validate :uniqueness_of_calculation_type_by_grade
  validate :uniqueness_of_initials_and_description_by_affected_score
  validate :grades_in_use_cant_be_removed
  validate :integral_calculation_score
  validates :year, presence: true, mask: { with: '9999', message: :incorrect_format }

  scope :by_description, lambda { |description|
    where(
      'unaccent(complementary_exam_settings.description) ILIKE unaccent(:description)',
      description: "%#{description}%"
    )
  }
  scope :by_initials, lambda { |initials|
    where(
      'unaccent(complementary_exam_settings.initials) ILIKE unaccent(:initials)',
      initials: "%#{initials}%"
    )
  }
  scope :by_affected_score, lambda { |affected_score| where(affected_score: affected_score) }
  scope :by_calculation_type, lambda { |calculation_type| where(calculation_type: calculation_type) }
  scope :by_grade_id, lambda { |grade_id| by_grade_id_scope(grade_id) }
  scope :by_year, lambda { |year| where(year: year) }
  scope :ordered, -> { order(year: :desc, description: :asc) }

  has_enumeration_for :affected_score, with: AffectedScoreTypes, create_helpers: true
  has_enumeration_for :calculation_type, with: CalculationTypes, create_helpers: true

  has_many :complementary_exams, dependent: :restrict_with_exception
  deferred_has_and_belongs_to_many :grades

  attr_readonly :year

  def to_s
    description
  end

  private

  def self.by_grade_id_scope(grade_id)
    where(<<-SQL, grade_id)
      EXISTS(
        SELECT 1
        FROM complementary_exam_settings_grades
        WHERE complementary_exam_settings_grades.complementary_exam_setting_id = complementary_exam_settings.id
        AND complementary_exam_settings_grades.grade_id IN (?)
      )
    SQL
  end

  def uniqueness_of_calculation_type_by_grade
    return true unless [CalculationTypes::SUBSTITUTION, CalculationTypes::SUBSTITUTION_IF_GREATER].include?(calculation_type)
    return true unless affected_score
    return true unless grades
    return true unless ComplementaryExamSetting.where.not(id: id)
                  .by_calculation_type([CalculationTypes::SUBSTITUTION, CalculationTypes::SUBSTITUTION_IF_GREATER])
                  .by_affected_score(affected_score)
                  .by_grade_id(grades.map(&:id))
                  .by_year(year)
                  .exists?

    errors.add(:base, :uniqueness_of_calculation_type_by_grade)
  end

  def uniqueness_of_initials_and_description_by_affected_score
    return true unless initials.present? && description.present? && affected_score.present?
    return true unless ComplementaryExamSetting.where.not(id: id)
                  .by_affected_score(affected_score)
                  .where('initials ILIKE ?', initials)
                  .where('description ILIKE ?', description)
                  .exists?

    errors.add(:base, :uniqueness_of_initials_and_description_by_affected_score)
  end

  def grades_in_use_cant_be_removed
    return true if new_record?
    return true if complementary_exams.count == complementary_exams.by_grade_id(grade_ids).count

    errors.add(:base, :grades_in_use_cant_be_removed)
  end

  def integral_calculation_score
    return unless integral?
    return if both?

    errors.add(:base, :integral_calculation_score)
  end
end
