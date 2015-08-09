FactoryGirl.define do
  factory :student do
    sequence(:name) { |n| "Student #{n}" }
    sequence(:api_code) { |n| n.to_s }
    api true
  end
end
