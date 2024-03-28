FactoryGirl.define do
  factory :user_role do
    user
    role
    unity

    trait :administrator do
      association :role, factory: [:role, :administrator]
    end

    trait :teacher do
      association :role, factory: [:role, :teacher]
    end
  end
end
