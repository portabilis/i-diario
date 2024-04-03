FactoryGirl.define do
  factory :role do
    association :author, factory: :user

    name { Faker::Lorem.unique.sentence }
    access_level AccessLevel::TEACHER

    trait :administrator do
      access_level AccessLevel::ADMINISTRATOR
    end

    trait :teacher do
      access_level AccessLevel::TEACHER
    end
  end
end
