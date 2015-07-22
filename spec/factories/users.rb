FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password   '12345678'
    password_confirmation '12345678'
    first_name 'User'
    last_name  'Example'
    login      'user.example'
    phone      '(11) 99887766'
    cpf        '639.290.118-32'
    admin      true
  end
end