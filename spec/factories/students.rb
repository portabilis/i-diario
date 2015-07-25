FactoryGirl.define do
  factory :student do
    sequence(:name) { |n| "Student #{n}" }
    sequence(:api_code) { |n| n }
    api true
  end
end
