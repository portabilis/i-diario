FactoryGirl.define do
  factory :knowledge_area do
    sequence(:api_code, &:to_s)
    description { Faker::Lorem.unique.sentence }
  end
end
