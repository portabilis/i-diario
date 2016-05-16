class AvaliationExemption < ActiveRecord::Base
  belongs_to :avaliation
  belongs_to :student

  audited
  has_associated_audits

  include Audit

  delegate :unity, to: :avaliation, prefix: false, allow_nil: true
  delegate :api_code, to: :unity, prefix: false, allow_nil: true
  delegate :classroom, to: :avaliation, prefix: false, allow_nil: true
  delegate :classroom_id, to: :avaliation, prefix: false, allow_nil: true
  delegate :grade_id, to: :classroom, prefix: false, allow_nil: true
  delegate :grade, to: :classroom, prefix: false, allow_nil: true
  delegate :discipline_id, to: :avaliation, prefix: false, allow_nil: true
  delegate :school_calendar, to: :avaliation, prefix: false, allow_nil: true
  delegate :step, to: :school_calendar, prefix: true, allow_nil: true
  delegate :course_id, to: :grade, prefix: false, allow_nil: true
end
