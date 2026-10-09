FactoryGirl.define do
  factory :iep_version do
    association :iep, factory: :individualized_educational_plan
    association :published_by, factory: :user
    classroom
    sequence(:name) { |n| "Version #{n}" }
    published_at { Time.current }
    active false
    content { {} }

    trait :current do
      active true
    end
  end
end
