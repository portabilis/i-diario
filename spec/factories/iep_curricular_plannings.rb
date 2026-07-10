FactoryGirl.define do
  factory :iep_curricular_planning do
    association :iep, factory: :individualized_educational_plan
    discipline

    trait :by_knowledge_area do
      discipline nil
      knowledge_area
    end
  end
end
