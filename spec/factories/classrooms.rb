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
  end
end