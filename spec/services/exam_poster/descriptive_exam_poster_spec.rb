require 'rails_helper'

RSpec.describe ExamPoster::DescriptiveExamPoster do
  let!(:discipline) { create(:discipline) }

  # Regra do 2º ano: não usa parecer descritivo (opinion_type DONT_USE)
  let(:rule_without_descriptive) { create(:exam_rule, opinion_type: OpinionTypes::DONT_USE) }
  # Regra do 1º ano: usa parecer descritivo por etapa e componente
  let(:rule_with_descriptive) do
    create(:exam_rule, :score_type_concept, opinion_type: OpinionTypes::BY_STEP_AND_DISCIPLINE)
  end

  let!(:descriptive_exam) do
    create(
      :descriptive_exam,
      :with_teacher_discipline_classroom,
      discipline: discipline,
      classroom: classroom,
      opinion_type: OpinionTypes::BY_STEP_AND_DISCIPLINE
    )
  end

  let(:student) { create(:student) }

  let!(:descriptive_exam_student) do
    create(:descriptive_exam_student, descriptive_exam: descriptive_exam, student: student)
  end

  let(:teacher) { Teacher.find(descriptive_exam.teacher_id) }

  let(:exam_posting) do
    create(
      :ieducar_api_exam_posting,
      post_type: ApiPostingTypes::DESCRIPTIVE_EXAM,
      school_calendar_classroom_step: classroom.calendar.classroom_steps.first,
      teacher: teacher
    )
  end

  subject { described_class.new(exam_posting, Entity.first.id) }

  # Turma multisseriada: cada série tem seu próprio exam_rule. Aqui a série SEM
  # parecer (2º ano) é cadastrada primeiro, ficando como classrooms_grades.first.
  # Antes da correção, o poster usava `classroom.first_exam_rule` e barrava o envio.
  context 'when classroom is multi-grade and the first grade does not use descriptive exam' do
    let!(:classroom) do
      create(:classroom, :with_classroom_semester_steps).tap do |new_classroom|
        # 2º ano (sem parecer) cadastrado primeiro -> menor id -> classrooms_grades.first
        create(:classrooms_grade, classroom: new_classroom, exam_rule: rule_without_descriptive)
        # 1º ano (com parecer descritivo) cadastrado depois
        create(:classrooms_grade, classroom: new_classroom, exam_rule: rule_with_descriptive)
      end
    end

    it 'enqueues the request using the grade that allows descriptive exam' do
      subject.post!

      request = {
        info: {
          classroom: classroom.api_code,
          student: student.api_code,
          discipline: discipline.api_code
        },
        request: {
          etapa: exam_posting.step.to_number,
          resource: 'pareceres-por-etapa-e-componente',
          pareceres: {
            classroom.api_code => {
              student.api_code => {
                discipline.api_code => {
                  'valor' => descriptive_exam_student.value
                }
              }
            }
          }
        }
      }

      expect(Ieducar::SendPostWorker).to have_enqueued_sidekiq_job(
        Entity.first.id,
        exam_posting.id,
        request[:request],
        request[:info],
        'critical',
        0
      )
    end
  end

  # Garante que a correção não passou a enviar indevidamente: se NENHUMA série da
  # turma usa parecer descritivo, o envio continua bloqueado.
  context 'when no grade in the classroom allows descriptive exam' do
    let!(:classroom) do
      create(:classroom, :with_classroom_semester_steps).tap do |new_classroom|
        create(:classrooms_grade, classroom: new_classroom, exam_rule: rule_without_descriptive)
      end
    end

    it 'does not enqueue any request' do
      subject.post!

      expect(subject.instance_variable_get(:@requests)).to be_empty
    end
  end
end
