FactoryGirl.define do
  factory :classroom do
    description 'Example Classroom'
    year        2020
    api_code    '1234'
    unity_code  '1234'

    unity
    exam_rule
  end
end