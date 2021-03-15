module SchoolTermable
  extend ActiveSupport::Concern

  included do
    validates_date :start_date_for_posting, :end_date_for_posting
    validates :start_at, :end_at, :start_date_for_posting, :end_date_for_posting, presence: true
  end

  def to_s
    "#{school_term} (#{localized.start_at} a #{localized.end_at})"
  end

  def to_number
    step_number
  end

  def step_type_description
    @step_type_description ||= school_calendar_parent.step_type_description
  end

  def school_term
    "#{to_number}º #{step_type_description}"
  end
end
