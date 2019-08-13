FactoryGirl.define do
  factory :school_calendar_classroom do
    classroom

    school_calendar {
      classroom.calendar.try(:school_calendar) || create(:school_calendar, unity: classroom.unity)
    }

    trait :school_calendar_classroom_with_trimester_steps do
      after(:build) do |school_calendar_classroom|
        year = school_calendar_classroom.school_calendar.year

        (1..3).each do |trimester|
          school_calendar_classroom.classroom_steps.build(
            attributes_for(
              :school_calendar_classroom_step,
              step_number: trimester,
              start_at: Date.new(year, (trimester * 3 - 2), 10),
              end_at: Date.new(year, (trimester * 3), 20),
              start_date_for_posting: Date.new(year, (trimester * 3 - 2), 10),
              end_date_for_posting: Date.new(year, (trimester * 3), 1).end_of_month
            )
          )
        end
      end
    end

    trait :school_calendar_classroom_with_semester_steps do
      after(:build) do |school_calendar_classroom|
        year = school_calendar_classroom.school_calendar.year

        (1..2).each do |semester|
          school_calendar_classroom.classroom_steps.build(
            attributes_for(
              :school_calendar_classroom_step,
              step_number: semester,
              start_at: Date.new(year, (semester * 6 - 5), 1),
              end_at: Date.new(year, (semester * 6), 1).end_of_month,
              start_date_for_posting: Date.new(year, (semester * 6 - 5), 1),
              end_date_for_posting: Date.new(year, (semester * 6), 1).end_of_month
            )
          )
        end
      end
    end
  end
end
