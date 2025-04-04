FactoryGirl.define do
  factory :transfer_note do
    discipline
    student
    teacher

    association :classroom, factory: [:classroom, :with_classroom_semester_steps]

    step_number 1
    transfer_date { Date.current }

    after(:build) do |transfer_note|
      if transfer_note.classroom.calendar.present?
        step = transfer_note.classroom.calendar.classroom_steps.first
      else
        step = transfer_note.classroom.unity.school_calendars.find_by(year: Date.current.year).steps.first
      end

      if transfer_note.recorded_at.blank?
        transfer_note.recorded_at = Date.current
      end

      transfer_note.step_number = step.try(:step_number) || 1 if transfer_note.step_number.zero?
      transfer_note.step_id = step.try(:id) if transfer_note.step_id.blank?
    end

    after(:build) do |transfer_note|
      transfer_note.daily_note_students.build(
        build(:daily_note_student, note: 5).attributes
      )
    end

    trait :with_teacher_discipline_classroom do
      after(:build) do |transfer_note|
        create(
          :teacher_discipline_classroom,
          classroom: transfer_note.classroom,
          discipline: transfer_note.discipline,
          teacher: transfer_note.teacher
        )
      end
    end
  end
end
