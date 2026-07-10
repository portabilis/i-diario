FactoryGirl.define do
  factory :iep_curricular_planning_option do
    association :iep_curricular_planning, factory: :iep_curricular_planning
    association :iep_option, factory: :iep_option
  end
end
