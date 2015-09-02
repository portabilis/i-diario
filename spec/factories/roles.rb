FactoryGirl.define do
  factory :role do
    sequence(:name) { |n| "Example Role #{n}" }
    kind RoleKind::EMPLOYEE

    association :author, factory: :user
  end
end