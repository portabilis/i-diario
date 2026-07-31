FactoryGirl.define do
  factory :iep_review_date do
    association :iep, factory: :individualized_educational_plan
    review_date { Date.current }
  end
end
