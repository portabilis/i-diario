FactoryGirl.define do
  factory :discipline do
    description 'Example Discipline'
    sequence(:api_code) { |n| n }
  end
end