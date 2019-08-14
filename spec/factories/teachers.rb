FactoryGirl.define do
  factory :teacher do
    sequence(:api_code, &:to_s)
    name { Faker::Name.unique.name_with_middle }

    transient do
      discipline nil
    end

    trait :with_teacher_discipline_classroom do
      after(:create) do |teacher, evaluator|
        discipline = evaluator.discipline || create(:discipline)

        create(
          :classroom,
          :with_teacher_discipline_classroom,
          discipline: discipline,
          teacher: teacher
        )
      end
    end
  end
end
