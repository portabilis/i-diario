require 'active_support/concern'

module TestSettingValidations
  extend ActiveSupport::Concern

  included do
    validates :exam_setting_type, presence: true
    validates :year, presence: true
    validates :average_calculation_type, presence: true
    validates :school_term_type_step, presence: { if: :by_school_term?  }
    validates :unities, presence: true, if: :general_by_school?
    validates :default_division_weight,
              presence: true,
              numericality: {
                only_integer: true,
                greater_than_or_equal_to: 1,
                less_than_or_equal_to: 1000
              }, if: :general_by_school?
    validates :maximum_score, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 1000 }
    validates :number_of_decimal_places, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 3 }

    validate :uniqueness_of_general_test_setting,        if: :general?
    validate :uniqueness_of_by_school_term_test_setting, if: :by_school_term?
    validate :uniqueness_of_by_general_by_school_test_setting, if: :general_by_school?
    validate :at_least_one_assigned_test, if: :sum?
    validate :tests_weight_less_or_equal_maximum_score, if: :should_validate_tests_weight?
    validate :ensure_can_destroy_test_settings
  end

  OVERLAPPING_LABELS_LIMIT = 3

  private

  def uniqueness_of_general_test_setting
    test_settings = TestSetting.where(year: year).where.not(exam_setting_type: ExamSettingTypes::GENERAL_BY_SCHOOL)
    test_settings = test_settings.where.not(id: id) if persisted?

    errors.add(:year, :taken) if test_settings.any?
  end

  def uniqueness_of_by_school_term_test_setting
    general_test_settings = TestSetting.where(year: year, exam_setting_type: ExamSettingTypes::GENERAL)
    general_test_settings = general_test_settings.where.not(id: id) if persisted?

    by_school_term_test_settings = TestSetting.where(year: year, school_term_type_step: school_term_type_step)
    by_school_term_test_settings = by_school_term_test_settings.where.not(id: id) if persisted?

    errors.add(:year, :taken) if general_test_settings.any?
    errors.add(:school_term_type_step, :taken) if by_school_term_test_settings.any?
  end

  def uniqueness_of_by_general_by_school_test_setting
    overlapping_test_settings = overlapping_general_by_school_test_settings
    return if overlapping_test_settings.empty?

    overlapping_grade_ids = overlapping_grade_ids(overlapping_test_settings)
    message_options = { year: year, unities: overlapping_unities_label(overlapping_test_settings) }
    return errors.add(:grades, :all_grades_in_another_test_setting, message_options) if overlapping_grade_ids.nil?

    message_options.update(count: overlapping_grade_ids.size, grades: grades_label(overlapping_grade_ids))
    errors.add(:grades, :in_another_test_setting, message_options)
  end

  def overlapping_general_by_school_test_settings
    test_settings = TestSetting.where(year: year, exam_setting_type: ExamSettingTypes::GENERAL_BY_SCHOOL)
    test_settings = test_settings.where.not(id: id) if persisted?
    # basta uma unidade em comum para uma turma ficar com duas configurações candidatas
    test_settings = test_settings.by_intersecting_unities(unities)
    test_settings = test_settings.where("grades && ARRAY[?]::integer[] OR grades = '{}'", grades) if grades.present?

    test_settings.to_a
  end

  # grades vazio significa "todas as séries"; retorna nil quando as duas configurações cobrem todas.
  # A coluna aceita NULL, que a busca só retorna quando esta configuração cobre todas as séries.
  def overlapping_grade_ids(overlapping_test_settings)
    other_grade_ids = overlapping_test_settings.map { |test_setting| test_setting.grades.to_a }
    other_covers_all_grades = other_grade_ids.any?(&:empty?)

    if grades.blank?
      other_grade_ids.flatten.uniq unless other_covers_all_grades
    elsif other_covers_all_grades
      grades.uniq
    else
      other_grade_ids.flat_map { |grade_ids| grades & grade_ids }.uniq
    end
  end

  def overlapping_unities_label(overlapping_test_settings)
    unity_ids = overlapping_test_settings.flat_map { |test_setting| unities & test_setting.unities }.uniq
    unity_names = Unity.with_discarded.where(id: unity_ids).map(&:to_s)

    I18n.t(
      'activerecord.errors.models.test_setting.overlapping_unities',
      count: unity_names.size,
      unities: summarized_labels(unity_names)
    )
  end

  # o curso é carregado à parte porque o includes aplicaria o default_scope e esconderia curso descartado
  def grades_label(grade_ids)
    overlapping_grades = Grade.with_discarded.where(id: grade_ids).to_a
    courses = Course.with_discarded.where(id: overlapping_grades.map(&:course_id)).index_by(&:id)

    summarized_labels(overlapping_grades.map { |grade| "#{grade} - #{courses[grade.course_id]}" })
  end

  def summarized_labels(labels)
    sorted_labels = labels.sort
    summarized = sorted_labels.first(OVERLAPPING_LABELS_LIMIT)
    remaining_count = sorted_labels.size - summarized.size

    if remaining_count.positive?
      summarized << I18n.t('activerecord.errors.models.test_setting.remaining_labels', count: remaining_count)
    end

    summarized.to_sentence
  end

  def at_least_one_assigned_test
    errors.add(:tests, :at_least_one_assigned_test) if tests.empty? { |test| !test.marked_for_destruction? }
  end

  def should_validate_tests_weight?
    sum? && tests.any? { |test| !test.marked_for_destruction? } && maximum_score
  end

  def tests_weight_less_or_equal_maximum_score
    return if default_division_weight.blank?

    tests_weight = tests.to_a.select { |test| !test.marked_for_destruction? && test.weight }.sum(&:weight)

    errors.add(:tests, :tests_weight_less_or_equal_maximum_score) unless (tests_weight / default_division_weight) <= maximum_score
  end

  def ensure_can_destroy_test_settings
    if tests.any?
      tests.each do |test_setting|
        if test_setting.avaliations.any? && test_setting.marked_for_destruction?
          errors.add(:base, :has_avaliation_associated)
          return false
        end
      end
    end
  end
end
