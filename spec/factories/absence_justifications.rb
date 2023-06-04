FactoryGirl.define do
  factory :absence_justification do
    user

    transient do
      teacher_discipline_classroom nil
    end

    students do
      create_list(:student, 1)
    end

    disciplines do
      create_list(:discipline, 1)
    end

    absence_date { Date.current }
    absence_date_end { Date.current + 1 }
    justification { Faker::Lorem.sentence }

    after(:build) do |absence_justification, evaluator|
      teacher_discipline_classroom = evaluator.teacher_discipline_classroom || create(:teacher_discipline_classroom, :with_classroom_semester_steps)

      absence_justification.classroom = teacher_discipline_classroom.classroom
      absence_justification.school_calendar = teacher_discipline_classroom.classroom.calendar.school_calendar
      absence_justification.unity = teacher_discipline_classroom.classroom.unity
      absence_justification.teacher = teacher_discipline_classroom.teacher

      # TODO: release-absence-justification
      # - [ ] Remover vínculo com professor (TeacherRelationable.ensure_has_teacher_id_informed)
      absence_justification.teacher_id = absence_justification.teacher.id
    end
  end
end
