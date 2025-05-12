FactoryGirl.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password '12345678'
    password_confirmation '12345678'
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    login { "#{first_name}_#{Faker::Name.middle_name}_#{last_name}" }
    phone '(11) 99887766'
    cpf { Faker::CPF.pretty }
    admin true

    trait :with_user_role_administrator do
      after(:create) do |user|
        user_role = create(:user_role, :administrator)
        user.user_roles << user_role
        user.current_user_role = user_role
        user.fullname = 'Admin'
        user.save!
      end
    end

    trait :with_user_role_teacher do
      after(:create) do |user|
        user_role = create(:user_role, :teacher)
        user.user_roles << user_role
        user.current_user_role = user_role
        user.save!
      end
    end

    factory :user_with_user_role do
      after(:create) do |user|
        user_role = create(:user_role)
        user.user_roles << user_role
        user.current_user_role = user_role
        user.save!
      end
    end
  end
end
