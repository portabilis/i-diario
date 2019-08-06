FactoryGirl.define do
  factory :lesson_plan do
    classroom
    association :school_calendar, factory: :school_calendar_with_one_step

    start_at '30/06/2020'
    end_at '30/07/2020'
    contents { [create(:content)] }

    factory :lesson_plan_without_contents do
      contents []
    end

    after(:build) do |lesson_plan|
      teacher_discipline_classroom = create(
        :teacher_discipline_classroom,
        classroom: lesson_plan.classroom
      )

      lesson_plan.teacher_id = teacher_discipline_classroom.teacher.id
    end
  end
end
