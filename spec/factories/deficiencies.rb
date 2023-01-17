FactoryGirl.define do
  factory :deficiency do
    sequence(:api_code, &:to_s)
    name { Faker::Name.unique.name_with_middle }
    disconsider_differentiated_exam_rule { true }
  end
end
