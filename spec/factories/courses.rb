FactoryGirl.define do
  factory :course do
    sequence(:api_code, &:to_s)
    description { Faker::Educator.course }
  end
end
