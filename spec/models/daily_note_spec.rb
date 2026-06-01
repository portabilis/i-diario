# encoding: utf-8
require 'rails_helper'

RSpec.describe DailyNote, type: :model do
  subject(:daily_note) { build(:daily_note) }

  describe 'associations' do
    it { expect(subject).to belong_to(:avaliation) }
    it { expect(subject).to have_many(:students).dependent(:destroy) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:avaliation) }
  end

  # O status (`complete`/`incomplete`) não é gravado: é calculado pela view
  # `daily_note_statuses` (gem scenic). Estes testes exercitam a view com dados
  # reais para garantir que alunos em busca ativa na data da avaliação não
  # impedem o diário de ficar `complete`.
  describe 'status (via daily_note_statuses view)' do
    let(:classroom) { create(:classroom, :with_classroom_semester_steps) }
    let(:classrooms_grade) { create(:classrooms_grade, classroom: classroom) }
    let(:avaliation) do
      create(:avaliation, :with_teacher_discipline_classroom, classroom: classroom, test_date: Date.current)
    end
    let(:daily_note) { create(:daily_note, avaliation: avaliation) }
    let(:test_date) { avaliation.test_date }

    # Cria um aluno matriculado e ativo na turma da avaliação na data do teste,
    # junto do respectivo daily_note_student. Retorna o student_enrollment para
    # permitir associar uma busca ativa no cenário.
    def enroll_student(note:)
      student = create(:student)
      student_enrollment = create(:student_enrollment, student: student)
      create(
        :student_enrollment_classroom,
        classrooms_grade: classrooms_grade,
        student_enrollment: student_enrollment,
        joined_at: (test_date - 30.days).to_s,
        left_at: ''
      )
      create(:daily_note_student, daily_note: daily_note, student: student, note: note, active: true)
      student_enrollment
    end

    def status
      daily_note.reload.daily_note_status.status
    end

    context 'when all active students have notes' do
      it 'is complete' do
        enroll_student(note: 8.0)

        expect(status).to eq(DailyNoteStatuses::COMPLETE)
      end
    end

    context 'when an active student has no note and is not in active search' do
      it 'is incomplete' do
        enroll_student(note: nil)

        expect(status).to eq(DailyNoteStatuses::INCOMPLETE)
      end
    end

    context 'when the only student without note is in active search covering the test date' do
      it 'is complete' do
        student_enrollment = enroll_student(note: nil)
        create(
          :active_search,
          student_enrollment: student_enrollment,
          start_date: test_date - 10.days,
          end_date: nil
        )

        expect(status).to eq(DailyNoteStatuses::COMPLETE)
      end
    end

    context 'when the student without note has an active search that ended before the test date' do
      it 'is incomplete' do
        student_enrollment = enroll_student(note: nil)
        create(
          :active_search,
          student_enrollment: student_enrollment,
          start_date: test_date - 30.days,
          end_date: test_date - 1.day
        )

        expect(status).to eq(DailyNoteStatuses::INCOMPLETE)
      end
    end

    context 'when the student without note has a discarded active search covering the test date' do
      it 'is incomplete' do
        student_enrollment = enroll_student(note: nil)
        active_search = create(
          :active_search,
          student_enrollment: student_enrollment,
          start_date: test_date - 10.days,
          end_date: nil
        )
        active_search.update_column(:discarded_at, Time.current)

        expect(status).to eq(DailyNoteStatuses::INCOMPLETE)
      end
    end
  end
end
