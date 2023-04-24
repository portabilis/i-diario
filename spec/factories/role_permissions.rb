FactoryGirl.define do
  factory :role_permission do
    association :role
    feature { 'roles' }
    permission { 'change' }
  end
end
