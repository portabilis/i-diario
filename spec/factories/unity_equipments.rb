FactoryGirl.define do
  factory :unity_equipment do
    sequence(:code) { |n| "#{n}" }
    biometric_type BiometricTypes::SAGEM

    association :unity, factory: :unity
  end
end