require 'rails_helper'

RSpec.describe InfrequencyTrackingNotifier, type: :service do
  # O roteamento da notificação de infrequência vai para a turma onde o aluno está matriculado.
  # Se a turma atual não tem falta dele (não dispararia), a notificação cai na turma onde as
  # faltas estão (origem de um transferido sem faltas na turma nova, ou aluno em limbo).
  describe '#students_with_absences' do
    let(:frequency_date) { Date.yesterday }
    let(:start_at) { Date.yesterday - 30 }

    let!(:classroom_a) { create(:classroom, :with_student_enrollment_classroom) }
    let(:enrollment_classroom_a) { classroom_a.student_enrollment_classrooms.first }
    let(:student) { enrollment_classroom_a.student_enrollment.student }

    subject(:notifier) { described_class.new }

    def absence_in(classroom)
      create(
        :unique_daily_frequency_student,
        classroom: classroom,
        student: student,
        frequency_date: frequency_date,
        present: false
      )
    end

    def students_with_absences(classroom)
      notifier.send(:students_with_absences, classroom.id, start_at)
    end

    context 'when the student is still enrolled in the classroom with absences' do
      before { absence_in(classroom_a) }

      it 'notifies the classroom' do
        expect(students_with_absences(classroom_a)).to contain_exactly(student.id)
      end
    end

    context 'when transferred and has absences in the current classroom' do
      let!(:classroom_b) { create(:classroom, :with_student_enrollment_classroom, student: student) }

      before do
        enrollment_classroom_a.update_attribute(:left_at, Date.yesterday - 1)
        absence_in(classroom_a)
        absence_in(classroom_b)
      end

      it 'does not notify the origin classroom' do
        expect(students_with_absences(classroom_a)).to eq([])
      end

      it 'notifies the current classroom' do
        expect(students_with_absences(classroom_b)).to contain_exactly(student.id)
      end
    end

    context 'when transferred but has no absences in the current classroom' do
      let!(:classroom_b) { create(:classroom, :with_student_enrollment_classroom, student: student) }

      before do
        enrollment_classroom_a.update_attribute(:left_at, Date.yesterday - 1)
        absence_in(classroom_a)
      end

      it 'notifies the origin classroom so the absences are not lost' do
        expect(students_with_absences(classroom_a)).to contain_exactly(student.id)
      end
    end

    context 'when the student is not enrolled in any classroom (limbo)' do
      before do
        enrollment_classroom_a.update_attribute(:left_at, Date.yesterday - 1)
        absence_in(classroom_a)
      end

      it 'notifies the origin classroom' do
        expect(students_with_absences(classroom_a)).to contain_exactly(student.id)
      end
    end

    context 'when left_at equals end_at (boundary: treated as already left)' do
      let!(:classroom_b) { create(:classroom, :with_student_enrollment_classroom, student: student) }

      before do
        enrollment_classroom_a.update_attribute(:left_at, Date.yesterday)
        absence_in(classroom_a)
        absence_in(classroom_b)
      end

      it 'does not notify the origin on the exit day (strict < left_at)' do
        expect(students_with_absences(classroom_a)).to eq([])
      end
    end

    context 'when the only other enrollment with an absence is inactive' do
      let!(:classroom_b) { create(:classroom, :with_student_enrollment_classroom, student: student) }

      before do
        enrollment_classroom_a.update_attribute(:left_at, Date.yesterday - 1)
        classroom_b.student_enrollment_classrooms.first.student_enrollment
                   .update_attribute(:active, IeducarBooleanState::INACTIVE)
        create(:unique_daily_frequency_student, classroom: classroom_a, student: student,
                                                frequency_date: Date.yesterday, present: false)
        create(:unique_daily_frequency_student, classroom: classroom_b, student: student,
                                                frequency_date: Date.yesterday - 5, present: false)
      end

      it 'notifies the origin (an inactive enrollment does not cover the absence)' do
        expect(students_with_absences(classroom_a)).to contain_exactly(student.id)
      end
    end

    context 'when in limbo with absences in more than one past classroom' do
      let!(:classroom_c) { create(:classroom, :with_student_enrollment_classroom, student: student) }
      let(:enrollment_classroom_c) { classroom_c.student_enrollment_classrooms.first }

      before do
        enrollment_classroom_a.update_attribute(:left_at, Date.yesterday - 1)
        enrollment_classroom_c.update_attribute(:left_at, Date.yesterday - 1)
        create(:unique_daily_frequency_student, classroom: classroom_a, student: student,
                                                frequency_date: Date.yesterday - 10, present: false)
        create(:unique_daily_frequency_student, classroom: classroom_c, student: student,
                                                frequency_date: Date.yesterday, present: false)
      end

      it 'notifies only the classroom of the most recent absence' do
        expect(students_with_absences(classroom_c)).to contain_exactly(student.id)
        expect(students_with_absences(classroom_a)).to eq([])
      end
    end
  end
end
