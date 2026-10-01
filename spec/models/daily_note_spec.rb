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
    let(:classrooms_grade) { create(:classrooms_grade, classroom: classroom, grade_id: avaliation.grade_ids.first) }
    let(:avaliation) do
      create(:avaliation, :with_teacher_discipline_classroom, classroom: classroom, test_date: Date.current)
    end
    let(:daily_note) { create(:daily_note, avaliation: avaliation) }
    let(:test_date) { avaliation.test_date }

    # Cria um aluno matriculado na turma da avaliação, por padrão enturmado desde antes da data do teste.
    # Retorna o student_enrollment para permitir associar busca ativa ou dispensa no cenário.
    def enroll_student_in_classroom(joined_at: (test_date - 30.days).to_s, left_at: '', grade: classrooms_grade)
      student_enrollment = create(:student_enrollment, student: create(:student))
      create(
        :student_enrollment_classroom,
        classrooms_grade: grade,
        student_enrollment: student_enrollment,
        joined_at: joined_at,
        left_at: left_at
      )
      student_enrollment
    end

    def exempt_from_avaliation(student)
      # A avaliação é recarregada porque a turma em memória guarda as séries de antes da enturmação.
      create(:avaliation_exemption, avaliation: Avaliation.find(avaliation.id), student: student,
                                    teacher_id: avaliation.teacher_id)
    end

    # Cria um aluno matriculado e ativo na turma da avaliação na data do teste,
    # junto do respectivo daily_note_student.
    def enroll_student(note:)
      student_enrollment = enroll_student_in_classroom
      create(:daily_note_student, daily_note: daily_note, student: student_enrollment.student, note: note, active: true)
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

    context 'when one student without note is in active search but another without note is not' do
      it 'is incomplete' do
        enroll_student(note: nil)
        student_enrollment_in_active_search = enroll_student(note: nil)
        create(
          :active_search,
          student_enrollment: student_enrollment_in_active_search,
          start_date: test_date - 10.days,
          end_date: nil
        )

        expect(status).to eq(DailyNoteStatuses::INCOMPLETE)
      end
    end

    context 'when the active search is on another enrollment of the student, outside the avaliation classroom' do
      it 'is incomplete' do
        student_enrollment = enroll_student(note: nil)
        other_enrollment = create(:student_enrollment, student: student_enrollment.student)
        create(
          :active_search,
          student_enrollment: other_enrollment,
          start_date: test_date - 10.days,
          end_date: nil
        )

        expect(status).to eq(DailyNoteStatuses::INCOMPLETE)
      end
    end

    context 'when the student without note has an active search starting after the test date' do
      it 'is incomplete' do
        student_enrollment = enroll_student(note: nil)
        create(
          :active_search,
          student_enrollment: student_enrollment,
          start_date: test_date + 1.day,
          end_date: nil
        )

        expect(status).to eq(DailyNoteStatuses::INCOMPLETE)
      end
    end

    context 'when the active search starts exactly on the test date' do
      it 'is complete' do
        student_enrollment = enroll_student(note: nil)
        create(
          :active_search,
          student_enrollment: student_enrollment,
          start_date: test_date,
          end_date: nil
        )

        expect(status).to eq(DailyNoteStatuses::COMPLETE)
      end
    end

    context 'when the active search ends exactly on the test date' do
      it 'is complete' do
        student_enrollment = enroll_student(note: nil)
        create(
          :active_search,
          student_enrollment: student_enrollment,
          start_date: test_date - 5.days,
          end_date: test_date
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

    # Diário sem linha de aluno para a view avaliar: a pendência vem das enturmações que a lista do diário mostraria.
    context 'when the daily note has no student rows' do
      # A regra de diário sem linha vale a partir do ano letivo de 2026, e a factory cria a turma no ano da data
      # corrente; o ano é fixado depois de criar a avaliação, que valida a data contra o calendário da turma.
      before do
        daily_note
        classroom.update_column(:year, 2026)
      end

      it 'is incomplete when a student is enrolled on the test date' do
        enroll_student_in_classroom

        expect(status).to eq(DailyNoteStatuses::INCOMPLETE)
      end

      it 'is incomplete when only discarded rows exist and a student is enrolled on the test date' do
        student_enrollment = enroll_student_in_classroom
        create(:daily_note_student, daily_note: daily_note, student: student_enrollment.student, active: true)
          .update_column(:discarded_at, Time.current)

        expect(status).to eq(DailyNoteStatuses::INCOMPLETE)
      end

      it 'is complete when no student is enrolled in the classroom' do
        expect(status).to eq(DailyNoteStatuses::COMPLETE)
      end

      it 'is complete when the classroom school year is before 2026' do
        enroll_student_in_classroom
        classroom.update_column(:year, 2025)

        expect(status).to eq(DailyNoteStatuses::COMPLETE)
      end

      it 'is complete when the only student joins the classroom after the test date' do
        enroll_student_in_classroom(joined_at: (test_date + 1.day).to_s)

        expect(status).to eq(DailyNoteStatuses::COMPLETE)
      end

      it 'is complete when the only student left the classroom on the test date' do
        enroll_student_in_classroom(left_at: test_date.to_s)

        expect(status).to eq(DailyNoteStatuses::COMPLETE)
      end

      it 'is complete when the only student is enrolled in a grade outside the avaliation' do
        enroll_student_in_classroom(grade: create(:classrooms_grade, classroom: classroom))

        expect(status).to eq(DailyNoteStatuses::COMPLETE)
      end

      it 'is complete when the only student enrollment is inactive' do
        enroll_student_in_classroom.update_column(:active, IeducarBooleanState::INACTIVE)

        expect(status).to eq(DailyNoteStatuses::COMPLETE)
      end

      it 'is complete when the only student is in active search on the test date' do
        create(:active_search, student_enrollment: enroll_student_in_classroom,
                               start_date: test_date - 10.days, end_date: nil)

        expect(status).to eq(DailyNoteStatuses::COMPLETE)
      end

      it 'is complete when the only student is exempted from the avaliation' do
        exempt_from_avaliation(enroll_student_in_classroom.student)

        expect(status).to eq(DailyNoteStatuses::COMPLETE)
      end

      it 'is incomplete when the exemption from the avaliation is discarded' do
        exempt_from_avaliation(enroll_student_in_classroom.student).update_column(:discarded_at, Time.current)

        expect(status).to eq(DailyNoteStatuses::INCOMPLETE)
      end

      # A lista do diário filtra por tipo de nota como StudentEnrollmentClassroom.by_score_type_query.
      it 'is complete when the student grade uses a concept exam rule and the classroom has a numeric grade' do
        concept_grade = create(:classrooms_grade, :score_type_concept, classroom: classroom,
                                                                       grade_id: avaliation.grade_ids.first)
        create(:classrooms_grade, classroom: classroom)
        enroll_student_in_classroom(grade: concept_grade)

        expect(status).to eq(DailyNoteStatuses::COMPLETE)
      end

      it 'is incomplete when no classroom grade uses a numeric exam rule' do
        concept_grade = create(:classrooms_grade, :score_type_concept, classroom: classroom,
                                                                       grade_id: avaliation.grade_ids.first)
        enroll_student_in_classroom(grade: concept_grade)

        expect(status).to eq(DailyNoteStatuses::INCOMPLETE)
      end

      it 'is complete when the student uses a differentiated concept exam rule' do
        classrooms_grade.exam_rule.update!(differentiated_exam_rule: create(:exam_rule, :score_type_concept))
        enroll_student_in_classroom.student.update_column(:uses_differentiated_exam_rule, true)

        expect(status).to eq(DailyNoteStatuses::COMPLETE)
      end

      it 'is incomplete when the student uses a differentiated numeric exam rule' do
        classrooms_grade.exam_rule.update!(differentiated_exam_rule: create(:exam_rule))
        enroll_student_in_classroom.student.update_column(:uses_differentiated_exam_rule, true)

        expect(status).to eq(DailyNoteStatuses::INCOMPLETE)
      end

      # A lista do diário tira a matrícula com dependência só em outra disciplina, como by_discipline_query.
      it 'is complete when the only student is a dependence student of another discipline' do
        create(:student_enrollment_dependence, student_enrollment: enroll_student_in_classroom,
                                               discipline: create(:discipline))

        expect(status).to eq(DailyNoteStatuses::COMPLETE)
      end

      it 'is incomplete when the only student is a dependence student of the avaliation discipline' do
        create(:student_enrollment_dependence, student_enrollment: enroll_student_in_classroom,
                                               discipline: avaliation.discipline)

        expect(status).to eq(DailyNoteStatuses::INCOMPLETE)
      end

      it 'is complete when the only student enrollment classroom is discarded' do
        enroll_student_in_classroom.student_enrollment_classrooms.first.update_column(:discarded_at, Time.current)

        expect(status).to eq(DailyNoteStatuses::COMPLETE)
      end

      it 'is complete when the only student enrollment is discarded' do
        enroll_student_in_classroom.update_column(:discarded_at, Time.current)

        expect(status).to eq(DailyNoteStatuses::COMPLETE)
      end

      it 'is complete when the student classroom grade is discarded' do
        enroll_student_in_classroom
        classrooms_grade.update_column(:discarded_at, Time.current)

        expect(status).to eq(DailyNoteStatuses::COMPLETE)
      end

      it 'is incomplete when the only numeric grade of the classroom is discarded' do
        concept_grade = create(:classrooms_grade, :score_type_concept, classroom: classroom,
                                                                       grade_id: avaliation.grade_ids.first)
        create(:classrooms_grade, classroom: classroom).update_column(:discarded_at, Time.current)
        enroll_student_in_classroom(grade: concept_grade)

        expect(status).to eq(DailyNoteStatuses::INCOMPLETE)
      end

      it 'is incomplete when the active search on the test date is discarded' do
        create(:active_search, student_enrollment: enroll_student_in_classroom,
                               start_date: test_date - 10.days, end_date: nil)
          .update_column(:discarded_at, Time.current)

        expect(status).to eq(DailyNoteStatuses::INCOMPLETE)
      end
    end
  end
end
