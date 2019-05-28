class DeficiencyStudent < ActiveRecord::Base
  include Discardable

  audited

  belongs_to :deficiency
  belongs_to :student

  default_scope -> { kept }

  scope :by_deficiency_id, ->(deficiency_id) { where(deficiency_id: deficiency_id) }
  scope :by_student_id, ->(student_id) { where(student_id: student_id) }
  scope :by_unity_id, ->(unity_id) { where(unity_id: unity_id) }
end
