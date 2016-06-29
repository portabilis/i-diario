FactoryGirl.define do
  factory :role do
    sequence(:name) { |n| "Example Role #{n}" }
    access_level AccessLevel::TEACHER

    association :author, factory: :user
  end
end
