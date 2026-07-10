FactoryGirl.define do
  factory :individualized_educational_plan do
    student
    unity
    classroom
    teacher
    year { Date.current.year }
    elaborated_at { Date.current }

    trait :with_aee_teacher do
      association :aee_teacher, factory: :teacher
    end

    trait :finalized do
      after(:create) do |iep|
        create(:iep_version, :current, iep: iep)
      end
    end
  end
end
