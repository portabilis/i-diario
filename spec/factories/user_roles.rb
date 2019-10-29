FactoryGirl.define do
  factory :user_role do
    user
    role
    unity

    trait :administrator do
      association :role, factory: [:role, :administrator]
    end
  end
end
