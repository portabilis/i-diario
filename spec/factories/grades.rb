FactoryGirl.define do
  factory :grade do
    course

    sequence(:api_code, &:to_s)
    description { course.description }
  end
end
