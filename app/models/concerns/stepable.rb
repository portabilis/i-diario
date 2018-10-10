module Stepable
  extend ActiveSupport::Concern

  attr_accessor :step_id, :ignore_step, :ignore_school_day

  included do
    validates_date :recorded_at
    validates_presence_of :classroom_id, :recorded_at
    validates_presence_of :step_id, unless: :ignore_step
    validates :recorded_at, not_in_future: true, posting_date: true
    validate :recorded_at_is_in_selected_step
    validate :ensure_is_school_day, unless: :ignore_school_day
  end

  module ClassMethods
    def by_recorded_at_between(start_at, end_at)
      where(arel_table[:recorded_at].gteq(start_at)).where(arel_table[:recorded_at].lteq(end_at))
    end

    def by_step_id(classroom, step_id)
      step = StepsFetcher.new(classroom).steps.find(step_id)

      by_recorded_at_between(step.start_at, step.end_at)
    end
  end

  def steps_fetcher
    @steps_fetcher ||= StepsFetcher.new(classroom)
  end

  def step
    return steps_fetcher.steps.find(step_id) if step_id.present?

    steps_fetcher.step(recorded_at)
  end

  def school_calendar
    @school_calendar ||= step.try(:school_calendar)
  end

  private

  def ensure_is_school_day
    return unless recorded_at.present? && school_calendar.present?

    unless school_calendar.school_day?(recorded_at, classroom.grade, classroom, nil)
      errors.add(:recorded_at, :not_school_term_day)
    end
  end

  def recorded_at_is_in_selected_step
    return if step_id.blank? || recorded_at.blank?

    unless steps_fetcher.step_belongs_to_date?(step_id, recorded_at)
      errors.add(:recorded_at, :not_school_term_day)
    end
  end
end
