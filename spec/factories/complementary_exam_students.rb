FactoryGirl.define do
  factory :complementary_exam_student do
    complementary_exam
    student

    score 1
  end
end
