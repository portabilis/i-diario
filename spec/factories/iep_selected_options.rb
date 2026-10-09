FactoryGirl.define do
  factory :iep_selected_option do
    association :iep, factory: :individualized_educational_plan
    association :iep_option, factory: :iep_option
  end
end
