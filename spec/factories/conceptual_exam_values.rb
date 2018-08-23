FactoryGirl.define do
  factory :conceptual_exam_value do
    discipline { create(:discipline) }
    conceptual_exam
    value 5
  end
end
