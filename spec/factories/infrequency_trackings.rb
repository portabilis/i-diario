FactoryGirl.define do
  factory :infrequency_tracking do
    student
    classroom

    notification_date { Date.current }
    notification_type { InfrequencyTrackingTypes::CONSECUTIVE_ABSENCES }
    notification_data { [{ teacher_id: 1, absences: [Date.current.to_s] }] }
  end
end
