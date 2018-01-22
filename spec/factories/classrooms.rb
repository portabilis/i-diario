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

    factory :classroom_numeric_and_concept do
      year { Time.zone.today.year }
      association :exam_rule, factory: :exam_rule_numeric_and_concept
    end
  end
end