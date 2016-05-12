class TransferNote < ActiveRecord::Base
  acts_as_copy_target

  audited
  has_associated_audits

  include Audit

  attr_accessor :unity_id

  belongs_to :classroom
  belongs_to :discipline
  belongs_to :school_calendar_step
  belongs_to :student

  validates :classroom,  presence: true
  validates :discipline, presence: true
  validates :school_calendar_step, presence: true
  validates :transfer_date, presence: true
  validates :student, presence: true
end
