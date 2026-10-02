# frozen_string_literal: true

require 'rails_helper'

# Com a configuração "apresentar enturmações inativas" ligada, um aluno que saiu e retornou à MESMA
# turma aparece em duas linhas — a enturmação ativa na data da avaliação e a de retorno (inativa na
# data). O esperado é uma linha ativa e uma "Não enturmado", e o registro salvo (que carrega a nota)
# deve ficar sempre na linha ATIVA.
RSpec.describe DailyNotesController, 'reload_students_list — return to the same classroom' do
  let(:controller) { DailyNotesController.new }
  let(:daily_note) { DailyNote.new }
  let(:test_date) { Date.new(2026, 6, 22) }
  let(:student) { instance_double(Student, id: 983) }

  let(:original_enrollment_classroom_id) { 1 } # enturmação original (sequence menor, iterada 1º)
  let(:return_enrollment_classroom_id) { 2 }   # enturmação de retorno (sequence maior, iterada 2º)
  # qual enturmação está ativa na data da avaliação (default: a original)
  let(:active_classroom_id) { original_enrollment_classroom_id }

  def enrollment(enrollment_classroom_id)
    {
      student: student,
      student_enrollment: instance_double(StudentEnrollment, id: 145_331),
      student_enrollment_classroom: instance_double(StudentEnrollmentClassroom, id: enrollment_classroom_id)
    }
  end

  before do
    controller.instance_variable_set(:@daily_note, daily_note)
    allow(daily_note).to receive(:test_date).and_return(test_date)

    allow(controller).to receive(:set_students_and_info) do
      controller.instance_variable_set(:@students, [])
      controller.instance_variable_set(:@normal_students, [])
      controller.instance_variable_set(:@dependence_students, [])
    end

    allow(controller).to receive(:set_student_enrollments_data) do
      controller.instance_variable_set(:@dependencies, {})
      controller.instance_variable_set(:@exempted_from_avaliation, [])
      controller.instance_variable_set(:@exempted_from_discipline, {})
      controller.instance_variable_set(:@active_search, {})
      controller.instance_variable_set(:@active, { active_classroom_id => [test_date] })
    end

    # ordem por sequence: original (seq menor) antes da de retorno (seq maior)
    allow(controller).to receive(:set_enrollment_classrooms).and_return(
      [enrollment(original_enrollment_classroom_id), enrollment(return_enrollment_classroom_id)]
    )
  end

  def normal_students
    controller.instance_variable_get(:@normal_students)
  end

  context 'when the avaliation has no saved DailyNoteStudent yet (create screen)' do
    it 'shows one active row and one marked as not enrolled' do
      controller.send(:reload_students_list)

      expect(normal_students.size).to eq(2)
      expect(normal_students.map(&:object_id).uniq.size).to eq(2)
      expect(normal_students.map(&:active)).to contain_exactly(true, false)
    end
  end

  context 'when the avaliation was already saved and the ACTIVE enrollment is the original one' do
    let(:persisted) do
      note_student = daily_note.students.build(student_id: student.id)
      note_student.active = true
      note_student
    end

    before { persisted } # força a criação do registro salvo antes do reload

    it 'keeps two distinct rows with the saved record on the active row' do
      controller.send(:reload_students_list)

      expect(normal_students.size).to eq(2)
      expect(normal_students.map(&:active)).to contain_exactly(true, false)
      expect(normal_students.find(&:active)).to equal(persisted)
      expect(normal_students.reject(&:active).first).not_to equal(persisted)
    end
  end

  context 'when the avaliation was already saved and the ACTIVE enrollment is the return one (higher sequence)' do
    # Avaliação numa data em que a enturmação de retorno é a ativa. O registro salvo (com a nota)
    # precisa ficar na linha ATIVA (a de retorno). Se cair na linha inativa, a linha ativa cria um
    # novo registro ativo e o save quebra com RecordNotUnique.
    let(:active_classroom_id) { return_enrollment_classroom_id }

    let(:persisted) do
      note_student = daily_note.students.build(student_id: student.id)
      note_student.active = true
      note_student
    end

    before { persisted }

    it 'puts the saved record on the active (return) row, not on the inactive one' do
      controller.send(:reload_students_list)

      expect(normal_students.size).to eq(2)
      expect(normal_students.map(&:active)).to contain_exactly(true, false)
      expect(normal_students.find(&:active)).to equal(persisted)
      expect(normal_students.reject(&:active).first).not_to equal(persisted)
    end
  end

  context 'when no enrollment is active on the test date and there is a saved record' do
    # Nenhuma enturmação do aluno está ativa na data: ele aparece só em linhas inativas. O registro
    # salvo é reaproveitado (para exibir a nota) sem fabricar um segundo registro ativo.
    let(:active_classroom_id) { 0 } # nenhuma das enturmações está ativa

    let(:persisted) do
      note_student = daily_note.students.build(student_id: student.id)
      note_student.active = true
      note_student
    end

    before { persisted }

    it 'reuses the saved record on an inactive row and marks every row as not enrolled' do
      controller.send(:reload_students_list)

      expect(normal_students.size).to eq(2)
      expect(normal_students.map(&:active)).to eq([false, false])
      expect(normal_students).to include(persisted)
    end
  end

  context 'when the student has more than one saved record and an active enrollment' do
    # Aluno com dois registros salvos (um ativo, um inativo — ex.: dado legado anterior ao índice
    # único parcial). A linha ativa reaproveita o registro ATIVO (que carrega a nota), sem casar por
    # posição no array.
    let(:active_saved_record) do
      note_student = daily_note.students.build(student_id: student.id)
      note_student.active = true
      note_student
    end

    let(:inactive_saved_record) do
      note_student = daily_note.students.build(student_id: student.id)
      note_student.active = false
      note_student
    end

    before do
      inactive_saved_record # construído primeiro, para a linha ativa não poder casar por posição
      active_saved_record
    end

    it 'reuses the active saved record on the active row, not the first by position' do
      controller.send(:reload_students_list)

      expect(normal_students.find(&:active)).to equal(active_saved_record)
    end
  end
end
