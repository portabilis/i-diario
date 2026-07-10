class IepSelectedOption < ApplicationRecord
  audited

  belongs_to :iep, class_name: 'IndividualizedEducationalPlan',
             foreign_key: :individualized_educational_plan_id
  belongs_to :iep_option

  validates :iep_option_id, presence: true
end
