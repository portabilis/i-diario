class AbsenceJustification < ActiveRecord::Base
  acts_as_copy_target

  audited

  include Audit

  belongs_to :author, class_name: 'User'
  belongs_to :student

  validates :author, presence: true
  validates :student, presence: true
  validates :absence_date_end, presence: true,
                               uniqueness: { scope: :student_id }
  validates :absence_date, presence: true,
                           uniqueness: { scope: :student_id }
  validates :justification, presence: true

  scope :by_author, lambda { |author_id| where(author_id: author_id).uniq }
  scope :ordered, -> { order(arel_table[:absence_date]) }
end