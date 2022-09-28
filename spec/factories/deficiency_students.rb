FactoryGirl.define do
  factory :deficiency_student do
    student
    deficiency
    unity_id { nil }
  end
end
