FactoryGirl.define do
  factory :discipline do
    description 'Example Discipline'
    sequence(:api_code) { |n| n.to_s }

    knowledge_area
  end
end