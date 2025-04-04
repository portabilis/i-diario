FactoryGirl.define do
  factory :content_record do
    teacher
    association :classroom, factory: [:classroom, :score_type_numeric, :with_classroom_semester_steps]

    transient do
      discipline nil
      contents_count 1
    end

    before(:create) do |content_record|
      classroom = content_record.classroom || create(
        :classroom,
        :score_type_numeric,
        :with_classroom_semester_steps
      )

      content_record.classroom = classroom if content_record.classroom.blank?

      if content_record.record_date.blank?
        step = classroom.calendar.classroom_steps.first
        content_record.record_date = Date.current
      end

      if content_record.teacher_id.blank? && content_record.teacher.present?
        content_record.teacher_id = content_record.teacher.id
      end
    end

    trait :with_contents do
      before(:create) do |content_record, evaluator|
        content_record.contents = create_list(:content, evaluator.contents_count)
      end
    end

    trait :with_teacher_discipline_classroom do
      after(:build) do |content_record, evaluator|
        teacher = Teacher.find(content_record.teacher_id) if content_record.teacher_id.present?
        teacher ||= evaluator.teacher || create(:teacher)
        content_record.teacher_id = teacher.id if content_record.teacher_id.blank?
        discipline = evaluator.discipline || create(:discipline)

        create(
          :teacher_discipline_classroom,
          classroom: content_record.classroom,
          discipline: discipline,
          teacher: teacher
        )
      end
    end
  end
end
