require 'rails_helper'

RSpec.describe ExamPoster::ConceptualExamPoster do
  let!(:discipline) { create(:discipline) }
  let!(:conceptual_exam) {
    create(
      :conceptual_exam,
      :with_teacher_discipline_classroom,
      :with_student_enrollment_classroom,
      :with_one_value,
      discipline: discipline,
      classroom: classroom
    )
  }
  let(:exam_posting) {
    create(
      :ieducar_api_exam_posting,
      school_calendar_classroom_step: classroom.calendar.classroom_steps.first,
      teacher: classroom.teacher_discipline_classrooms.first.teacher
    )
  }

  subject { described_class.new(exam_posting, Entity.first.id) }

  context 'when has differentiated_exam_rules' do
    let(:differentiated_exam_rule) { create(:exam_rule, score_type: ScoreTypes::CONCEPT) }
    let(:exam_rule) { create(:exam_rule, differentiated_exam_rule: differentiated_exam_rule) }
    let!(:classroom) {
      create(
        :classroom,
        :with_classroom_semester_steps,
        :score_type_numeric,
        exam_rule: exam_rule
      )
    }

    context 'when student uses_differentiated_exam_rule' do
      let(:conceptual_exam) {
        student = create(:student, uses_differentiated_exam_rule: true)
        create(
          :conceptual_exam,
          :with_teacher_discipline_classroom,
          :with_student_enrollment_classroom,
          :with_one_value,
          discipline: discipline,
          classroom: classroom,
          student: student
        )
      }

      it 'enqueue the requests' do
        subject.post!

        request = {
          info: {
            classroom: classroom.api_code,
            student: conceptual_exam.student.api_code,
            discipline: discipline.api_code
          },
          request: {
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
        }

        expect(Ieducar::SendPostWorker).to have_enqueued_sidekiq_job(
          Entity.first.id,
          exam_posting.id,
          request[:request],
          request[:info],
          "critical",
          0
        )
      end
    end
  end

  context 'when classroom score type is numeric and concept' do
    let(:classroom) {
      create(
        :classroom,
        :with_classroom_semester_steps,
        :score_type_numeric_and_concept
      )
    }

    context 'when discipline score type is numeric after being concept' do
      let(:teacher_discipline_classroom) {
        create(
          :teacher_discipline_classroom,
          classroom: classroom,
          discipline: discipline,
          score_type: ScoreTypes::CONCEPT
        )
      }

      it 'does not enqueue the requests' do
        teacher_discipline_classroom.update(score_type: ScoreTypes::NUMERIC)

        subject.post!

        request = {
          info: {
            classroom: classroom.api_code,
            student: conceptual_exam.student.api_code,
            discipline: discipline.api_code
          },
          request: {
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
        }

        expect(Ieducar::SendPostWorker).not_to have_enqueued_sidekiq_job(
          Entity.first.id,
          exam_posting.id,
          request[:request],
          request[:info]
        )
      end
    end

    context 'when discipline score type is concept' do
      let(:teacher_discipline_classroom) {
        create(
          :teacher_discipline_classroom,
          classroom: classroom,
          discipline: discipline,
          score_type: ScoreTypes::CONCEPT
        )
      }

      it 'enqueues the requests' do
        subject.post!

        request = {
          info: {
            classroom: classroom.api_code,
            student: conceptual_exam.student.api_code,
            discipline: discipline.api_code
          },
          request: {
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
        }

        expect(Ieducar::SendPostWorker).to have_enqueued_sidekiq_job(
          Entity.first.id,
          exam_posting.id,
          request[:request],
          request[:info],
          "critical",
          0
        )
      end
    end

    context 'when discipline score type is numeric' do
      let(:teacher_discipline_classroom) {
        create(
          :teacher_discipline_classroom,
          classroom: classroom,
          discipline: discipline,
          score_type: ScoreTypes::NUMERIC
        )
      }

      it 'does not enqueue the requests' do
        subject.post!

        request = {
          info: {
            classroom: classroom.api_code,
            student: conceptual_exam.student.api_code,
            discipline: discipline.api_code
          },
          request: {
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
        }

        expect(Ieducar::SendPostWorker).not_to have_enqueued_sidekiq_job(
          Entity.first.id,
          exam_posting.id,
          request[:request],
          request[:info]
        )
      end
    end
  end

  context 'when classroom score type is numeric after being concept' do
    let(:classroom) {
      create(
        :classroom,
        :with_classroom_semester_steps,
        :score_type_concept
      )
    }

    it 'does not enqueue the requests' do
      classroom.classrooms_grades.first.exam_rule.update(score_type: ScoreTypes::NUMERIC)

      subject.post!

      request = {
        info: {
          classroom: classroom.api_code,
          student: conceptual_exam.student.api_code,
          discipline: discipline.api_code
        },
        request: {
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
      }

      expect(Ieducar::SendPostWorker).not_to have_enqueued_sidekiq_job(
        Entity.first.id,
        exam_posting.id,
        request[:request],
        request[:info]
      )
    end
  end

  context 'when classroom score type is concept' do
    let(:classroom) {
      create(
        :classroom,
        :with_classroom_semester_steps,
        :score_type_concept
      )
    }

    it 'enqueues the requests' do
      subject.post!

      request = {
        info: {
          classroom: classroom.api_code,
          student: conceptual_exam.student.api_code,
          discipline: discipline.api_code
        },
        request: {
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
      }

      expect(Ieducar::SendPostWorker).to have_enqueued_sidekiq_job(
        Entity.first.id,
        exam_posting.id,
        request[:request],
        request[:info],
        "critical",
        0
      )
    end
  end

  context 'when discipline is exempted' do
    let(:classroom) {
      create(
        :classroom,
        :with_classroom_semester_steps,
        :score_type_concept
      )
    }
    let(:specific_step) {
      create(
        :specific_step,
        classroom: classroom,
        discipline: discipline,
        used_steps: (classroom.calendar.classroom_steps.first.to_number + 1)
      )
    }

    it 'does not enqueue the requests' do
      subject.post!

      request = {
        info: {
          classroom: classroom.api_code,
          student: conceptual_exam.student.api_code,
          discipline: discipline.api_code
        },
        request: {
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
      }

      expect(Ieducar::SendPostWorker).not_to have_enqueued_sidekiq_job(
        Entity.first.id,
        exam_posting.id,
        request[:request],
        request[:info]
      )
    end
  end

  context 'when student discipline is exempted' do
    let(:classroom) {
      create(
        :classroom,
        :with_classroom_semester_steps,
        :score_type_concept
      )
    }
    let!(:student_enrollment_exempted_discipline) {
      create(
        :student_enrollment_exempted_discipline,
        discipline: discipline,
        student_enrollment: conceptual_exam.student.student_enrollments.first
      )
    }

    it 'does not return warning_messages and ignores the conceptual_exam_value' do
      subject.post!

      expect(subject.instance_variable_get(:@warning_messages)).to be_empty
      expect(subject.instance_variable_get(:@requests)).to be_empty
    end

    it 'returns a warning message when the student has no conceptual_exam_value and is exempt from another discipline' do
      discipline_other = create(:discipline)
      create(
        :teacher_discipline_classroom,
        classroom: classroom,
        discipline: discipline_other,
        teacher: classroom.teacher_discipline_classrooms.first.teacher,
        score_type: ScoreTypes::CONCEPT
      )
      create(:conceptual_exam_value,
        conceptual_exam: conceptual_exam,
        discipline: discipline_other,
        value: nil
      )

      subject.post!

      response = [
        "O aluno #{conceptual_exam.student.name} não possui nota lançada no diário de notas conceituais na " \
        "turma #{classroom.description} disciplina: #{discipline_other.description}"
      ]

      expect(subject.instance_variable_get(:@warning_messages)).to eq(response)
    end
  end
end
