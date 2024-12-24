FactoryGirl.define do
  factory :unique_daily_frequency_student do
    classroom
    student

    frequency_date { Date.current }
    present true
    absences_by []
  end
end
