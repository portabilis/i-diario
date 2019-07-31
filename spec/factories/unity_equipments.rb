FactoryGirl.define do
  factory :unity_equipment do
    unity

    sequence(:code, &:to_s)
    biometric_type BiometricTypes::SAGEM
  end
end
