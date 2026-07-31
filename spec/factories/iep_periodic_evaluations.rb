FactoryGirl.define do
  factory :iep_periodic_evaluation do
    association :iep, factory: :individualized_educational_plan
    discipline
    iep_review_date { create(:iep_review_date, iep: iep) }

    trait :by_knowledge_area do
      discipline nil
      knowledge_area
    end
  end
end
