class StudentBiometric < ActiveRecord::Base
  acts_as_copy_target
  audited
  include Audit
  include Discardable

  has_enumeration_for :biometric_type, with: BiometricTypes

  belongs_to :student

  default_scope -> { kept }

  validates :student_id, presence: true
  validates :biometric, presence: true
  validates :biometric_type, presence: true, uniqueness: { scope: :student_id }

  def to_s
    biometric
  end
end
