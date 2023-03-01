FactoryGirl.define do
  factory :absence_justifications_student do
    student
    absence_justification

    trait :with_daily_frequency do
      after(:create) do |absence_justifications_student|
        absence_justification = absence_justifications_student.absence_justification

        daily_frequency = create(
          :daily_frequency,
          unity: absence_justification.unity,
          classroom: absence_justification.classroom,
          school_calendar: absence_justification.school_calendar,
          frequency_date: absence_justification.absence_date
        )

        create(
          :daily_frequency_student,
          daily_frequency: daily_frequency,
          absence_justification_student_id: absence_justifications_student.id
        )
      end
    end
  end
end
