FactoryGirl.define do
  factory :teacher do
    sequence(:api_code, &:to_s)
    name { Faker::Name.unique.name_with_middle }
  end
end
