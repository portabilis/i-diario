FactoryGirl.define do
  factory :conceptual_exam do
    classroom
    school_calendar_step
    student
    recorded_at { Time.zone.today }
  end
end
