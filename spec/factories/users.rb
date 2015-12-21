FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password   '12345678'
    password_confirmation '12345678'
    first_name 'User'
    last_name  'Example'
    login      'user.example'
    phone      '(11) 99887766'
    cpf        { Faker::CPF.pretty }
    admin      true

    factory :user_with_user_role do
      after(:build) do |user|
        user.user_roles.build(user: user, role: create(:role), unity: create(:unity))
      end
    end
  end
end
