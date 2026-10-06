require 'rails_helper'

RSpec.describe ContentsForDisciplineRecordFetcher, type: :service do
  let(:teacher) { create(:teacher) }
  let(:discipline) { create(:discipline) }
  let(:school_term_type) { create(:school_term_type, description: 'Anual') }
  let(:school_term_type_step) { create(:school_term_type_step) }
  let(:classroom) {
    create(
      :classroom,
      :with_classroom_semester_steps
    )
  }
  let(:classrooms_grade) { create(:classrooms_grade, classroom: classroom) }
  let(:teacher_discipline_classroom) {
    create(
      :teacher_discipline_classroom,
      discipline: discipline,
      teacher: teacher,
      classroom: classroom,
      grade: classrooms_grade.grade
    )
  }

  before do
    teacher_discipline_classroom
    allow_any_instance_of(TeachingPlan).to receive(:yearly?).and_return(true)
  end

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
      grade: classroom.first_grade,
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
    date = Date.current

    teaching_plan = create(
      :teaching_plan,
      school_term_type: school_term_type,
      school_term_type_step: school_term_type_step,
      grade: classroom.first_grade,
      teacher: teacher,
      teacher_id: teacher.id,
      year: classroom.calendar.school_calendar.year,
      unity: classroom.unity
    )

    create(:discipline_teaching_plan, teaching_plan: teaching_plan, discipline: discipline)

    subject = described_class.new(teacher, classroom, discipline, date)

    expect(subject.fetch).to match_array teaching_plan.contents
  end

  it 'fetches lesson plan contents in the plan order' do
    contents = create_list(:content, 3)
    plan_order = [contents[1], contents[0], contents[2]]
    lesson_plan = create(
      :lesson_plan,
      classroom: classroom,
      teacher: teacher,
      teacher_id: teacher.id,
      contents: contents.reverse
    )
    create(:discipline_lesson_plan, lesson_plan: lesson_plan, discipline: discipline, teacher_id: teacher.id)

    # O UPDATE grava uma nova versão da linha no fim da tabela; atualizar de trás para frente deixa a
    # ordem física oposta à de position, e um fetch sem ORDER BY não acerta por coincidência.
    plan_order.each_with_index.to_a.reverse_each do |content, index|
      lesson_plan.contents_lesson_plans.where(content_id: content.id).update_all(position: index)
    end

    subject = described_class.new(teacher, classroom, discipline, lesson_plan.start_at)

    expect(subject.fetch).to eq plan_order
  end
end
