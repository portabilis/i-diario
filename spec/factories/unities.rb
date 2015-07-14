FactoryGirl.define do
  factory :unity do
    name     'Example Unity'
    unit_type UnitTypes::SCHOOL_UNIT

    association :author, factory: :user
  end
end