FactoryGirl.define do
  factory :student do
    sequence(:api_code, &:to_s)
    name { Faker::Name.unique.name_with_middle }
    api true
  end
end
