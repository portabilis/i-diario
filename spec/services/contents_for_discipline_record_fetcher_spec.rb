require 'rails_helper'

RSpec.describe ContentsForDisciplineRecordFetcher do
  let(:teacher) { create(:teacher) }
  let(:classroom) { create(:classroom) }
  let(:discipline) { create(:discipline) }

  it 'fetches contents from lesson plan' do
    lesson_plan = create(:lesson_plan, classroom: classroom, teacher_id: teacher.id)
    date = lesson_plan.start_at

    teaching_plan = create(
      :teaching_plan,
      grade: classroom.grade,
      teacher_id: teacher.id,
      year: date.year
    )

    create(:discipline_lesson_plan, lesson_plan: lesson_plan, discipline: discipline)
    create(:discipline_teaching_plan, teaching_plan: teaching_plan, discipline: discipline)

    subject = described_class.new(teacher, classroom, discipline, date)

    expect(subject.fetch).to match_array lesson_plan.contents
  end

  it 'fetches contents from teaching plan' do
    school_calendar = create(
      :school_calendar_with_one_step,
      unity_id: classroom.unity_id,
      year: classroom.year
    )
    date = 1.business_days.after(Date.parse("#{school_calendar.year}-01-01"))

    teaching_plan = create(
      :teaching_plan,
      :yearly,
      grade: classroom.grade,
      teacher_id: teacher.id,
      year: school_calendar.year,
      unity: classroom.unity
    )

    create(:discipline_teaching_plan, teaching_plan: teaching_plan, discipline: discipline)

    subject = described_class.new(teacher, classroom, discipline, date)

    expect(subject.fetch).to match_array teaching_plan.contents
  end
end
