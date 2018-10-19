require 'rails_helper'

RSpec.describe ExamPoster::ConceptualExamPoster do
  let!(:exam_posting) do
    create(:ieducar_api_exam_posting,
           school_calendar_step: school_calendar.steps.first,
           teacher: teacher_discipline_classroom.teacher)
  end
  let!(:conceptual_exam) do
    create(:conceptual_exam_with_one_value, school_calendar_step: school_calendar.steps.first, classroom: classroom)
  end
  let!(:school_calendar) { create(:school_calendar, :school_calendar_with_semester_steps, :current) }
  let!(:discipline) { conceptual_exam.conceptual_exam_values.first.discipline }
  let!(:teacher_discipline_classroom) do
    create(:teacher_discipline_classroom,
           classroom: classroom,
           discipline: discipline)
  end

  subject { described_class.new(exam_posting, Entity.first.id, 'exam_posting_send') }

  context 'when has differentiated_exam_rules' do
    let(:differentiated_exam_rule) { create(:exam_rule, score_type: ScoreTypes::CONCEPT) }
    let(:exam_rule) { create(:exam_rule, differentiated_exam_rule: differentiated_exam_rule) }
    let!(:classroom) { create(:classroom_numeric, unity: school_calendar.unity, exam_rule: exam_rule) }

    context 'when student uses_differentiated_exam_rule' do
      let!(:conceptual_exam) do
        student = create(:student, uses_differentiated_exam_rule: true)
        create(:conceptual_exam_with_one_value,
              school_calendar_step: school_calendar.steps.first,
              classroom: classroom,
              student: student)
      end

      it 'enqueue the requests' do
        subject.post!

        request = {
          etapa: exam_posting.step.to_number,
          resource: 'notas',
          notas: {
            classroom.api_code => {
              conceptual_exam.student.api_code => {
                discipline.api_code => {
                  nota: conceptual_exam.conceptual_exam_values.first.value.to_s
                }
              }
            }
          }
        }

        expect(Ieducar::SendPostWorker).
          to have_enqueued_sidekiq_job(Entity.first.id, exam_posting.id, request)
      end
    end
  end

  context 'when classroom score type is numeric and concept' do
    let!(:classroom) { create(:classroom_numeric_and_concept, unity: school_calendar.unity) }

    context 'when discipline score type is numeric after being concept' do
      let!(:teacher_discipline_classroom) do
        create(:teacher_discipline_classroom,
               classroom: classroom,
               discipline: discipline,
               score_type: DisciplineScoreTypes::CONCEPT)
      end

      it 'does not enqueue the requests' do
        teacher_discipline_classroom.update_column(:score_type, DisciplineScoreTypes::NUMERIC)

        subject.post!

        request = {
          etapa: exam_posting.step.to_number,
          resource: 'notas',
          notas: {
            classroom.api_code => {
              conceptual_exam.student.api_code => {
                discipline.api_code => {
                  nota: conceptual_exam.conceptual_exam_values.first.value.to_s
                }
              }
            }
          }
        }

        expect(Ieducar::SendPostWorker).
          to_not have_enqueued_sidekiq_job(Entity.first.id, exam_posting.id, request)
      end
    end

    context 'when discipline score type is concept' do
      let!(:teacher_discipline_classroom) do
        create(:teacher_discipline_classroom,
               classroom: classroom,
               discipline: discipline,
               score_type: DisciplineScoreTypes::CONCEPT)
      end

      it 'enqueues the requests' do
        subject.post!

        request = {
          etapa: exam_posting.step.to_number,
          resource: 'notas',
          notas: {
            classroom.api_code => {
              conceptual_exam.student.api_code => {
                discipline.api_code => {
                  nota: conceptual_exam.conceptual_exam_values.first.value.to_s
                }
              }
            }
          }
        }

        expect(Ieducar::SendPostWorker).
          to have_enqueued_sidekiq_job(Entity.first.id, exam_posting.id, request)
      end
    end

    context 'when discipline score type is numeric' do
      let!(:teacher_discipline_classroom) do
        create(:teacher_discipline_classroom,
               classroom: classroom,
               discipline: discipline,
               score_type: DisciplineScoreTypes::NUMERIC)
      end

      it 'does not enqueue the requests' do
        subject.post!

        request = {
          etapa: exam_posting.step.to_number,
          resource: 'notas',
          notas: {
            classroom.api_code => {
              conceptual_exam.student.api_code => {
                discipline.api_code => {
                  nota: conceptual_exam.conceptual_exam_values.first.value.to_s
                }
              }
            }
          }
        }

        expect(Ieducar::SendPostWorker).
          to_not have_enqueued_sidekiq_job(Entity.first.id, exam_posting.id, request)
      end
    end
  end

  context 'when classroom score type is numeric after being concept' do
    let!(:classroom) { create(:classroom_concept, unity: school_calendar.unity) }

    it 'does not enqueue the requests' do
      classroom.exam_rule.update_column(:score_type, ScoreTypes::NUMERIC)

      subject.post!

      request = {
        etapa: exam_posting.step.to_number,
        resource: 'notas',
        notas: {
          classroom.api_code => {
            conceptual_exam.student.api_code => {
              discipline.api_code => {
                nota: conceptual_exam.conceptual_exam_values.first.value.to_s
              }
            }
          }
        }
      }

      expect(Ieducar::SendPostWorker).
        to_not have_enqueued_sidekiq_job(Entity.first.id, exam_posting.id, request)
    end
  end

  context 'when classroom score type is concept' do
    let!(:classroom) { create(:classroom_concept, unity: school_calendar.unity) }
    let!(:teacher_discipline_classroom) do
      create(:teacher_discipline_classroom,
             classroom: classroom,
             discipline: discipline)
    end

    it 'enqueues the requests' do
      subject.post!

      request = {
        etapa: exam_posting.step.to_number,
        resource: 'notas',
        notas: {
          classroom.api_code => {
            conceptual_exam.student.api_code => {
              discipline.api_code => {
                nota: conceptual_exam.conceptual_exam_values.first.value.to_s
              }
            }
          }
        }
      }

      expect(Ieducar::SendPostWorker).
        to have_enqueued_sidekiq_job(Entity.first.id, exam_posting.id, request)
    end
  end
end
