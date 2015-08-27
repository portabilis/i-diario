FactoryGirl.define do
  factory :grade do
    sequence(:description) { |n| "Grade #{n}" }
    sequence(:api_code)    { |n| n.to_s }

    course
  end
end