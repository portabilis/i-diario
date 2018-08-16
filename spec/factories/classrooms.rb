FactoryGirl.define do
  factory :classroom do
    description 'Example Classroom'
    year        2020
    sequence(:api_code) { |n| n.to_s }
    unity_code  '1234'
    period '1'

    unity
    exam_rule
    grade

    trait :current do
      year { Time.zone.today.year }
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
      association :exam_rule, factory: :exam_rule_by_discipline
    end
  end
end
