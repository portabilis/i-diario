FactoryGirl.define do
  factory :discipline do
    knowledge_area

    sequence(:api_code, &:to_s)
    description { Faker::Lorem.unique.sentence }

    transient do
      teacher nil
    end

    trait :with_teacher_discipline_classroom do
      after(:create) do |discipline, evaluator|
        teacher = evaluator.teacher || create(:teacher)

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
