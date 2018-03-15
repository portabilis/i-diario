FactoryGirl.define do
  factory :conceptual_exam do
    classroom
    school_calendar_step
    student
    recorded_at { Time.zone.today }
    unity_id 1

    factory :conceptual_exam_with_one_value do
      after(:build) do |conceptual_exam|
        discipline_id = create(:discipline).id
        conceptual_exam.conceptual_exam_values.build(attributes_for(:conceptual_exam_value, discipline_id: discipline_id))
      end
    end
  end
end
