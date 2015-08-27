FactoryGirl.define do
  factory :knowledge_area do
    sequence(:description) { |n| "Example Knowledge Area #{n}" }
    sequence(:api_code)    { |n| n.to_s }
  end
end