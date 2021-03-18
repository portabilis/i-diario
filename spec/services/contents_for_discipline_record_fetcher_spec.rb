require 'rails_helper'

RSpec.describe ContentsForDisciplineRecordFetcher do
  let(:teacher) { create(:teacher) }
  let(:discipline) { create(:discipline) }
  let(:school_term_type) { create(:school_term_type) }
  let(:school_term_type_step) { create(:school_term_type_step) }
  let(:classroom) {
    create(
      :classroom,
      :with_teacher_discipline_classroom,
      :with_classroom_semester_steps,
      discipline: discipline,
      teacher: teacher
    )
  }

  it 'fetches contents from lesson plan' do
    lesson_plan = create(
      :lesson_plan,
      classroom: classroom,
      teacher: teacher,
      teacher_id: teacher.id
    )
    date = lesson_plan.start_at
    teaching_plan = create(
      :teaching_plan,
      grade: classroom.grade,
      teacher: teacher,
      teacher_id: teacher.id,
      year: date.year
    )

    create(
      :discipline_lesson_plan,
      lesson_plan: lesson_plan,
      discipline: discipline,
      teacher_id: teacher.id
    )
    create(
      :discipline_teaching_plan,
      teaching_plan: teaching_plan,
      discipline: discipline,
      teacher_id: teacher.id
    )

    subject = described_class.new(teacher, classroom, discipline, date)

    expect(subject.fetch).to match_array lesson_plan.contents
  end

  it 'fetches contents from teaching plan' do
    date = classroom.calendar.classroom_steps.first.first_school_calendar_date

    teaching_plan = create(
      :teaching_plan,
      school_term_type: school_term_type,
      school_term_type_step: school_term_type_step,
      grade: classroom.grade,
      teacher: teacher,
      teacher_id: teacher.id,
      year: classroom.calendar.school_calendar.year,
      unity: classroom.unity
    )

    create(:discipline_teaching_plan, teaching_plan: teaching_plan, discipline: discipline)

    subject = described_class.new(teacher, classroom, discipline, date)

    expect(subject.fetch).to match_array teaching_plan.contents
  end
end
