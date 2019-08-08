FactoryGirl.define do
  factory :unity do
    association :author, factory: :user

    sequence(:api_code, &:to_s)
    name { Faker::University.unique.name }
    unit_type UnitTypes::SCHOOL_UNIT
  end
end
