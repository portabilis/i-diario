FactoryGirl.define do
  factory :conceptual_exam_value do
    discipline
    conceptual_exam

    value { rand(0..10) }
  end
end
