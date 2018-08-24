FactoryGirl.define do
  factory :complementary_exam do
    unity
    classroom
    discipline
    complementary_exam_setting
    recorded_at { Time.zone.today }

    after(:build) do |complementary_exam|
      complementary_exam.students << build(:complementary_exam_student, complementary_exam: complementary_exam)
    end
  end
end
