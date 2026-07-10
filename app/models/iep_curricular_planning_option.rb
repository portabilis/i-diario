class IepCurricularPlanningOption < ApplicationRecord
  audited

  belongs_to :iep_curricular_planning
  belongs_to :iep_option

  validates :iep_option_id, presence: true
end
