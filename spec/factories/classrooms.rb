FactoryGirl.define do
  factory :classroom do
    unity
    exam_rule
    grade

    description { Faker::Lorem.unique.sentence }
    year 2020
    sequence(:api_code, &:to_s)
    unity_code { unity.api_code }
    period { Periods.to_a.sample[1] }

    trait :current do
      year { Date.current.year }
    end

    factory :classroom_numeric_and_concept do
      current
      association :exam_rule, factory: :exam_rule_numeric_and_concept
    end

    factory :classroom_numeric do
      current
      association :exam_rule, factory: :exam_rule
    end

    factory :classroom_concept do
      current
      association :exam_rule, factory: :exam_rule_concept
    end

    trait :by_discipline do
      current
      association :exam_rule, factory: :exam_rule_by_discipline
    end
  end
end
