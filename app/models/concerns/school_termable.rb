module SchoolTermable
  extend ActiveSupport::Concern

  included do
    validates_date :start_date_for_posting, :end_date_for_posting
    validates :start_at, :end_at, :start_date_for_posting, :end_date_for_posting, presence: true
    validate :start_at_must_be_in_school_calendar_year, if: :school_calendar
  end

  def to_s
    "#{school_term} (#{localized.start_at} a #{localized.end_at})"
  end

  def to_number
    return if steps.blank?

    (steps.ordered.index(self) || 0) + 1
  end

  def raw_school_term
    @raw_school_term ||= school_calendar_parent.school_step(self).to_s
  end

  def school_term
    if raw_school_term.end_with?(SchoolTermTypes::BIMESTER)
      I18n.t("enumerations.bimesters.#{raw_school_term}")
    elsif raw_school_term.end_with?(SchoolTermTypes::TRIMESTER)
      I18n.t("enumerations.trimesters.#{raw_school_term}")
    elsif raw_school_term.end_with?(SchoolTermTypes::SEMESTER)
      I18n.t("enumerations.semesters.#{raw_school_term}")
    elsif raw_school_term.end_with?(SchoolTermTypes::YEARLY)
      I18n.t("enumerations.year.#{raw_school_term}")
    end
  end

  private

  def start_at_must_be_in_school_calendar_year
    return if errors[:start_at].any? || school_calendar.errors[:year].any?

    errors.add(:start_at, :must_be_in_school_calendar_year) if start_at.to_date.year != school_calendar.year.to_i
  end
end
