class AbsenceJustification < ActiveRecord::Base
  acts_as_copy_target

  audited

  include Audit

  belongs_to :student

  validates :student, :absence_date, :justification, presence: true
  validates :absence_date, uniqueness: {scope: :student_id}

  scope :ordered, -> { order(arel_table[:absence_date]) }
end