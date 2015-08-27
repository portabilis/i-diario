FactoryGirl.define do
  factory :course do
    sequence(:description) { |n| "Course #{n}" }
    sequence(:api_code)    { |n| n.to_s }
  end
end