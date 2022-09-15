FactoryGirl.define do
  factory :classrooms_grade do
    classroom
    grade
    exam_rule

    trait :score_type_numeric_and_concept do
      association :exam_rule, factory: [:exam_rule, :score_type_numeric_and_concept]
    end

    trait :score_type_numeric do
      association :exam_rule, factory: :exam_rule
    end

    trait :score_type_concept do
      association :exam_rule, factory: [:exam_rule, :score_type_concept]
    end

    trait :frequency_type_by_discipline do
      association :exam_rule, factory: [:exam_rule, :frequency_type_by_discipline]
    end
  end
end
