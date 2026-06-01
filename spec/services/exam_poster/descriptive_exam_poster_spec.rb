require 'rails_helper'

RSpec.describe ExamPoster::DescriptiveExamPoster do
  let(:rule_without_descriptive) { create(:exam_rule, opinion_type: OpinionTypes::DONT_USE) }

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
  # parecer é cadastrada primeiro e, por ter menor id, *tende* a ser retornada por
  # `classrooms_grades.first` — mas a associação não tem `ORDER BY`, então essa ordem
  # não é garantida. É justamente essa fragilidade do `first_exam_rule` que a correção
  # elimina ao validar contra todas as séries da turma.
  context 'when classroom is multi-grade and the first grade does not use descriptive exam' do
    let(:discipline) { create(:discipline) }
    let(:rule_with_descriptive) do
      create(:exam_rule, :score_type_concept, opinion_type: OpinionTypes::BY_STEP_AND_DISCIPLINE)
    end

    let!(:classroom) do
      create(:classroom, :with_classroom_semester_steps).tap do |new_classroom|
        # Série sem parecer cadastrada primeiro (menor id)
        create(:classrooms_grade, classroom: new_classroom, exam_rule: rule_without_descriptive)
        # Série com parecer descritivo cadastrada depois
        create(:classrooms_grade, classroom: new_classroom, exam_rule: rule_with_descriptive)
      end
    end

    let(:teacher) { create(:teacher) }
    let!(:teacher_discipline_classroom) do
      create(:teacher_discipline_classroom, classroom: classroom, discipline: discipline, teacher: teacher)
    end

    let(:student) { create(:student) }
    let!(:descriptive_exam) do
      create(:descriptive_exam, discipline: discipline, classroom: classroom, teacher_id: teacher.id,
                                opinion_type: OpinionTypes::BY_STEP_AND_DISCIPLINE)
    end
    let!(:descriptive_exam_student) do
      create(:descriptive_exam_student, descriptive_exam: descriptive_exam, student: student)
    end

    it 'has the grade without descriptive exam as first_exam_rule (precondition for the regression)' do
      expect(classroom.first_exam_rule).to eq(rule_without_descriptive)
    end

    it 'enqueues the request considering the grade that allows descriptive exam' do
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
        Entity.first.id, exam_posting.id, request[:request], request[:info], 'critical', 0
      )
    end
  end

  # Caminho geral (sem disciplina): opinion_type by_step. Exercita post_by_step,
  # que tem fonte de dados e shape de request distintos (sem discipline no info).
  context 'when opinion type is by_step (general, without discipline)' do
    let(:rule_with_descriptive) do
      create(:exam_rule, :score_type_concept, opinion_type: OpinionTypes::BY_STEP)
    end

    let!(:classroom) do
      create(:classroom, :with_classroom_semester_steps).tap do |new_classroom|
        create(:classrooms_grade, classroom: new_classroom, exam_rule: rule_with_descriptive)
      end
    end

    let(:teacher) { create(:teacher) }
    let!(:teacher_discipline_classroom) do
      create(:teacher_discipline_classroom, classroom: classroom, teacher: teacher)
    end

    let(:student) { create(:student) }
    let!(:descriptive_exam) do
      create(:descriptive_exam, discipline: nil, classroom: classroom, teacher_id: teacher.id,
                                opinion_type: OpinionTypes::BY_STEP)
    end
    let!(:descriptive_exam_student) do
      create(:descriptive_exam_student, descriptive_exam: descriptive_exam, student: student)
    end

    it 'enqueues the general (per-step) request' do
      subject.post!

      request = {
        info: {
          classroom: classroom.api_code,
          student: student.api_code
        },
        request: {
          etapa: exam_posting.step.to_number,
          resource: 'pareceres-por-etapa-geral',
          pareceres: {
            classroom.api_code => {
              student.api_code => {
                'valor' => descriptive_exam_student.value
              }
            }
          }
        }
      }

      expect(Ieducar::SendPostWorker).to have_enqueued_sidekiq_job(
        Entity.first.id, exam_posting.id, request[:request], request[:info], 'critical', 0
      )
    end
  end

  # Aluno que usa regra diferenciada: a regra base não usa parecer, mas a
  # diferenciada sim. Cobre o ramo `if differentiated` do valid_opinion_type?.
  context 'when the student uses a differentiated exam rule' do
    let(:discipline) { create(:discipline) }
    let(:differentiated_rule) do
      create(:exam_rule, :score_type_concept, opinion_type: OpinionTypes::BY_STEP_AND_DISCIPLINE)
    end
    let(:base_rule) do
      create(:exam_rule, opinion_type: OpinionTypes::DONT_USE, differentiated_exam_rule: differentiated_rule)
    end

    let!(:classroom) do
      create(:classroom, :with_classroom_semester_steps).tap do |new_classroom|
        create(:classrooms_grade, classroom: new_classroom, exam_rule: base_rule)
      end
    end

    let(:teacher) { create(:teacher) }
    let!(:teacher_discipline_classroom) do
      create(:teacher_discipline_classroom, classroom: classroom, discipline: discipline, teacher: teacher)
    end

    let(:student) { create(:student, uses_differentiated_exam_rule: true) }
    let!(:descriptive_exam) do
      create(:descriptive_exam, discipline: discipline, classroom: classroom, teacher_id: teacher.id,
                                opinion_type: OpinionTypes::BY_STEP_AND_DISCIPLINE)
    end
    let!(:descriptive_exam_student) do
      create(:descriptive_exam_student, descriptive_exam: descriptive_exam, student: student)
    end

    it 'enqueues the request using the differentiated rule opinion type' do
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
        Entity.first.id, exam_posting.id, request[:request], request[:info], 'critical', 0
      )
    end
  end

  # Guarda contra envio indevido: se nenhuma série da turma usa parecer
  # descritivo, nada é enfileirado.
  context 'when no grade in the classroom allows descriptive exam' do
    let(:discipline) { create(:discipline) }

    let!(:classroom) do
      create(:classroom, :with_classroom_semester_steps).tap do |new_classroom|
        create(:classrooms_grade, classroom: new_classroom, exam_rule: rule_without_descriptive)
      end
    end

    let(:teacher) { create(:teacher) }
    let!(:teacher_discipline_classroom) do
      create(:teacher_discipline_classroom, classroom: classroom, discipline: discipline, teacher: teacher)
    end

    let(:student) { create(:student) }
    let!(:descriptive_exam) do
      create(:descriptive_exam, discipline: discipline, classroom: classroom, teacher_id: teacher.id,
                                opinion_type: OpinionTypes::BY_STEP_AND_DISCIPLINE)
    end
    let!(:descriptive_exam_student) do
      create(:descriptive_exam_student, descriptive_exam: descriptive_exam, student: student)
    end

    it 'does not enqueue any request' do
      subject.post!

      expect(Ieducar::SendPostWorker.jobs).to be_empty
    end
  end
end
