FactoryGirl.define do
  factory :user do
    email      'john.doe@example.com'
    password   '12345678'
    password_confirmation '12345678'
    first_name 'John'
    last_name  'Doe'
    login      'john.doe'
    phone      '(11) 99887766'
    cpf        '639.290.118-32'
    admin      true
  end
end