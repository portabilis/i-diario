FactoryGirl.define do
  factory :discipline_content_record do
    content_record
    discipline

    after(:build) do |discipline_content_record|
      teacher_discipline_classroom = create(
        :teacher_discipline_classroom,
        discipline: discipline_content_record.discipline
      )

      discipline_content_record.teacher_id = teacher_discipline_classroom.teacher.id
    end
  end
end
