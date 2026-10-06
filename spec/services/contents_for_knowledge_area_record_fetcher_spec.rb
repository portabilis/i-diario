require 'rails_helper'

RSpec.describe ContentsForKnowledgeAreaRecordFetcher, type: :service do
  let(:teacher) { create(:teacher) }
  let(:knowledge_area) { create(:knowledge_area) }
  let(:school_term_type) { create(:school_term_type, description: 'Anual') }
  let(:school_term_type_step) { create(:school_term_type_step) }
  let(:classroom) { create(:classroom, :with_classroom_semester_steps) }
  let(:classrooms_grade) { create(:classrooms_grade, classroom: classroom) }
  let(:discipline) { create(:discipline, knowledge_area: knowledge_area) }
  let(:teacher_discipline_classroom) do
    create(
      :teacher_discipline_classroom,
      discipline: discipline,
      teacher: teacher,
      classroom: classroom,
      grade: classrooms_grade.grade
    )
  end
  let(:contents) { create_list(:content, 3) }

  # Ordem do plano diferente da ordem de inserção e da ordem dos ids: sem ORDER BY, a lista
  # sairia na ordem física das linhas ou na do índice escolhido pelo planner.
  let(:plan_order) { [contents[1], contents[0], contents[2]] }

  before do
    teacher_discipline_classroom
    allow_any_instance_of(TeachingPlan).to receive(:yearly?).and_return(true)
  end

  # O UPDATE grava uma nova versão da linha no fim da tabela; atualizar de trás para frente deixa a
  # ordem física oposta à de position, e um fetch sem ORDER BY não acerta por coincidência.
  def reorder_positions(join_rows, ordered_contents)
    ordered_contents.each_with_index.to_a.reverse_each do |content, index|
      join_rows.where(content_id: content.id).update_all(position: index)
    end
  end

  it 'fetches lesson plan contents in the plan order' do
    lesson_plan = create(
      :lesson_plan,
      classroom: classroom,
      teacher: teacher,
      teacher_id: teacher.id,
      contents: contents.reverse
    )
    create(
      :knowledge_area_lesson_plan,
      lesson_plan: lesson_plan,
      knowledge_area_ids: knowledge_area.id,
      teacher_id: teacher.id
    )
    reorder_positions(lesson_plan.contents_lesson_plans, plan_order)

    subject = described_class.new(teacher, classroom, [knowledge_area], lesson_plan.start_at)

    expect(subject.fetch).to eq plan_order
  end

  it 'fetches teaching plan contents in the plan order' do
    teaching_plan = create(
      :teaching_plan,
      school_term_type: school_term_type,
      school_term_type_step: school_term_type_step,
      grade: classroom.first_grade,
      teacher: teacher,
      teacher_id: teacher.id,
      year: classroom.calendar.school_calendar.year,
      unity: classroom.unity,
      contents: contents.reverse
    )
    create(
      :knowledge_area_teaching_plan,
      teaching_plan: teaching_plan,
      knowledge_area_ids: knowledge_area.id,
      teacher_id: teacher.id
    )
    reorder_positions(teaching_plan.contents_teaching_plans, plan_order)

    subject = described_class.new(teacher, classroom, [knowledge_area], Date.current)

    expect(subject.fetch).to eq plan_order
  end
end
