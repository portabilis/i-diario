FactoryGirl.define do
  factory :discipline_content_record do
    content_record
    discipline

    transient do
      teacher nil
      classroom nil
    end

    trait :with_teacher_discipline_classroom do
      after(:build) do |discipline_content_record, evaluator|
        if discipline_content_record.teacher_id.present?
          teacher = Teacher.find(discipline_content_record.teacher_id)
        end

        teacher ||= evaluator.teacher || create(:teacher)
        discipline_content_record.teacher_id = teacher.id if discipline_content_record.teacher_id.blank?
        classroom = evaluator.classroom || discipline_content_record.content_record.classroom

        create(
          :teacher_discipline_classroom,
          discipline: discipline_content_record.discipline,
          classroom: classroom,
          teacher: teacher
        )
      end
    end
  end
end
