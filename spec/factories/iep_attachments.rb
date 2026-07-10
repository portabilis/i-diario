FactoryGirl.define do
  factory :iep_attachment do
    association :iep, factory: :individualized_educational_plan
  end
end
