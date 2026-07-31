FactoryGirl.define do
  factory :iep_option do
    kind { IepOptionKinds::COMMUNICATION_PROFILE }
    sequence(:description) { |n| "Option #{n}" }
    sequence(:position) { |n| n }
    active true

    trait :communication_profile do
      kind { IepOptionKinds::COMMUNICATION_PROFILE }
    end

    trait :support_type do
      kind { IepOptionKinds::SUPPORT_TYPE }
    end

    trait :instructional_accommodation do
      kind { IepOptionKinds::INSTRUCTIONAL_ACCOMMODATION }
    end
  end
end
