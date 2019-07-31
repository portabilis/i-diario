FactoryGirl.define do
  factory :discipline do
    knowledge_area

    sequence(:api_code, &:to_s)
    description { Faker::Lorem.unique.sentence }
  end
end
