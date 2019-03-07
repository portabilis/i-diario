module TeacherRelationable
  extend ActiveSupport::Concern

  attr_accessor :teacher_id, :validation_type, :ignore_teacher

  included do
    before_destroy :set_validation_type_to_destroy
    before_validation :set_teacher_id
    before_validation :ensure_has_teacher_id_informed, if: :valid_validation_type?
    validate :ensure_teacher_can_post_to_classroom, if: :validate_classroom?
    validate :ensure_teacher_can_post_to_discipline, if: :validate_discipline?
    validate :ensure_teacher_can_post_to_classroom_and_discipline, if: :validate_classroom_and_discipline?
    validate :ensure_teacher_can_post_to_grade, if: :validate_grade?
    validate :ensure_teacher_can_post_to_knowledge_areas, if: :validate_knowledge_areas?
  end

  module ClassMethods
    attr_reader :validate_columns

    private

    def teacher_relation_columns(validate_columns)
      validate_columns = [validate_columns[:only]].flatten
      @validate_columns = {}
      @validate_columns[:classroom] = validate_columns.include?(:classroom)
      @validate_columns[:discipline] = validate_columns.include?(:discipline)
      @validate_columns[:grade] = validate_columns.include?(:grade)
      @validate_columns[:knowledge_areas] = validate_columns.include?(:knowledge_areas)
    end
  end

  def teacher_relation_fetcher
    @teacher_relation_fetcher ||= begin
      params = { teacher_id: teacher_id }
      params[:discipline_id] = discipline_id if validate_discipline?
      params[:classroom] = classroom if validate_classroom?
      params[:grade] = grade_id if validate_grade?
      params[:knowledge_areas] = knowledge_areas.map(&:id) if validate_knowledge_areas?

      TeacherRelationFetcher.new(params)
    end
  end

  private

  def set_teacher_id
    return if ignore_teacher && (!defined?(teacher) || teacher.nil?)

    self.teacher_id = teacher.id if defined?(teacher) && !teacher.nil?
  end

  def set_validation_type_to_destroy
    self.validation_type = :destroy
  end

  def valid_validation_type?
    validation_type != :destroy
  end

  def validate_columns?
    return false if ignore_teacher && teacher_id.nil?

    valid_validation_type?
  end

  def validate_classroom?
    self.class.validate_columns[:classroom] && validate_columns?
  end

  def validate_discipline?
    self.class.validate_columns[:discipline] && validate_columns?
  end

  def validate_classroom_and_discipline?
    self.class.validate_columns[:classroom] && self.class.validate_columns[:discipline] && validate_columns?
  end

  def validate_grade?
    self.class.validate_columns[:grade] && validate_columns?
  end

  def validate_knowledge_areas?
    self.class.validate_columns[:knowledge_areas] && validate_columns?
  end

  def ensure_has_teacher_id_informed
    return if ignore_teacher

    raise ArgumentError if valid_validation_type? && teacher_id.blank?
  end

  def ensure_teacher_can_post_to_classroom
    return if teacher_relation_fetcher.exists_classroom_in_relation?

    errors.add(:classroom_id, :not_belongs_to_teacher)
  end

  def ensure_teacher_can_post_to_discipline
    return if teacher_relation_fetcher.exists_discipline_in_relation?

    errors.add(:discipline_id, :not_belongs_to_teacher)
  end

  def ensure_teacher_can_post_to_classroom_and_discipline
    return if teacher_relation_fetcher.exists_classroom_and_discipline_in_relation?
    return unless teacher_relation_fetcher.exists_classroom_in_relation? &&
                  teacher_relation_fetcher.exists_discipline_in_relation?

    errors.add(:classroom_id, :not_belongs_to_teacher)
    errors.add(:discipline_id, :not_belongs_to_teacher)
  end

  def ensure_teacher_can_post_to_grade
    return if teacher_relation_fetcher.exists_grade_in_relation?

    errors.add(:grade_id, :not_belongs_to_teacher)
  end

  def ensure_teacher_can_post_to_knowledge_areas
    return if teacher_relation_fetcher.exists_all_knowledge_areas_in_relation?

    errors.add(:knowledge_area_ids, :not_belongs_to_teacher)
  end
end
