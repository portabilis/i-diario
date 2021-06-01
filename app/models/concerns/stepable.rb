module Stepable
  extend ActiveSupport::Concern

  attr_accessor :step_id, :ignore_step, :ignore_date_validates

  included do
    validates_date :recorded_at
    validates :classroom_id, :recorded_at, :step_number, presence: true
    validates :step_id, presence: true, unless: :ignore_step
    validates :recorded_at, not_in_future: true, unless: :ignore_date_validates
    validates :recorded_at, posting_date: true, unless: :ignore_date_validates
    validate :recorded_at_is_in_selected_step, unless: :ignore_date_validates
    validate :ensure_is_school_day, unless: :ignore_date_validates

    scope :by_step_id, lambda { |classroom, step_id|
      step = StepsFetcher.new(classroom).step_by_id(step_id)

      step.present? ? by_step_number(step.step_number) : where('1=2')
    }
  end

  module ClassMethods
    def by_step_number(step_number)
      where(step_number: step_number)
    end

    def by_recorded_at_between(start_at, end_at)
      where(arel_table[:recorded_at].gteq(start_at)).where(arel_table[:recorded_at].lteq(end_at))
    end
  end

  def steps_fetcher
    @steps_fetcher ||= StepsFetcher.new(classroom)
  end

  def step
    return steps_fetcher.step_by_id(step_id) if step_id.present?

    steps_fetcher.step(step_number)
  end

  def school_calendar
    @school_calendar ||= step.try(:school_calendar)
  end

  private

  def ensure_is_school_day
    return unless classroom.present? && recorded_at.present? && school_calendar.present?

    school_day = true
    grade_ids = classroom.grade_ids

    loop do
      grade_id = grade_ids&.shift
      school_day = false unless school_calendar.school_day?(recorded_at, grade_id, classroom.id, nil)

      break if grade_ids.blank? || !school_day
    end

    errors.add(:recorded_at, :not_school_term_day) unless school_day
  end

  def recorded_at_is_in_selected_step
    return if step_id.blank? || recorded_at.blank?
    return if steps_fetcher.step_belongs_to_date?(step_id, recorded_at)

    errors.add(:recorded_at, :not_school_term_day)
  end
end
