FactoryGirl.define do
  factory :individualized_educational_plan do
    student
    year { Date.current.year }
    elaborated_at { Date.current }

    trait :with_aee_teacher do
      association :aee_teacher, factory: :teacher
    end
  end
end
