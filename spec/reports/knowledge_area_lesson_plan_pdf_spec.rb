require 'rails_helper'

RSpec.describe KnowledgeAreaLessonPlanPdf, type: :report do

  skip "should be created knowledge_area_lesson_plan_pdf"
  let(:entity_configuration) { create(:entity_configuration) }
  let(:discipline) { create(:discipline) }
  let(:classroom) {
    create(
      :classroom,
      :with_teacher_discipline_classroom,
      :with_classroom_semester_steps,
      discipline: discipline
    )
  }
  let(:teacher_discipline_classroom) { classroom.teacher_discipline_classrooms.first }
  let(:lesson_plan) {
    create(
      :lesson_plan,
      classroom: classroom,
      teacher_id: teacher_discipline_classroom.teacher.id
    )
  }
  let(:knowledge_area_lesson_plan) {
    create(
      :knowledge_area_lesson_plan,
      lesson_plan: lesson_plan,
      knowledge_area_ids: discipline.knowledge_area.id,
      teacher_id: teacher_discipline_classroom.teacher.id
    )
  }

  context 'when the report parameters are correct' do
    subject(:knowledge_area_lesson_plan_pdf) do
      KnowledgeAreaLessonPlanPdf.build(
        entity_configuration,
        knowledge_area_lesson_plan,
        teacher_discipline_classroom.teacher
      ).render
    end

    it 'should report must be created' do
      skip 'because translation'
      expect(knowledge_area_lesson_plan_pdf).to be_truthy
    end

    it 'should report created with the title of objectives' do
      skip 'because translation'
      text_analysis = PDF::Inspector::Text.analyze(knowledge_area_lesson_plan_pdf).strings

      expect(text_analysis).to include('Objetivos')
    end

    it 'should created without the title of objectives' do
      skip 'because translation'
      current_configuration = GeneralConfiguration.first
      current_configuration.update(remove_lesson_plan_objectives: true)

      text_analysis = PDF::Inspector::Text.analyze(knowledge_area_lesson_plan_pdf).strings

      expect(text_analysis).not_to include('Objetivos')
    end
  end
end

