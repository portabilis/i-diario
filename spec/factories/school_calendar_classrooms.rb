FactoryGirl.define do
  factory :school_calendar_classroom do
    classroom
    school_calendar

    trait :school_calendar_classroom_with_semester_steps do
      after(:build) do |school_calendar_classroom|
        (1..2).each do |semester|
          school_calendar_classroom.classroom_steps
            .build(attributes_for(
                    :school_calendar_classroom_step,
                    start_at: Date.new(school_calendar_classroom.school_calendar.year, (semester * 6 - 5), 1),
                    end_at: Date.new(school_calendar_classroom.school_calendar.year, (semester * 6), 1).end_of_month,
                    start_date_for_posting: Date.new(school_calendar_classroom.school_calendar.year, (semester * 6 - 5), 1),
                    end_date_for_posting: Date.new(school_calendar_classroom.school_calendar.year, (semester * 6), 1).end_of_month
                  )
            )
        end
      end
    end
  end
end
