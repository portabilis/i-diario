class TeachingPlan < ActiveRecord::Base
  acts_as_copy_target

  audited

  include Audit

  belongs_to :classroom
  belongs_to :discipline
  belongs_to :school_calendar_step

  validates :classroom, presence: true
  validates :discipline, presence: true
  validates :school_calendar_step, presence: true
end
