FactoryGirl.define do
  factory :unity do
    sequence(:name) { |n| "Example Unity #{n}" }
    unit_type UnitTypes::SCHOOL_UNIT

    association :author, factory: :user
  end
end