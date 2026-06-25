require 'rails_helper'

RSpec.describe InfrequencyTrackingNotifier, type: :service do
  # O roteamento das notificações de infrequência vai para a turma onde o aluno está ativo.
  # A turma que o aluno deixou só é notificada quando ele não está ativo em nenhuma outra
  # turma (limbo).
  describe '#students_with_absences' do
    let(:frequency_date) { Date.yesterday }
    let(:start_at) { Date.yesterday - 30 }

    let!(:classroom) { create(:classroom, :with_student_enrollment_classroom) }
    let(:student_enrollment_classroom) { classroom.student_enrollment_classrooms.first }
    let(:student) { student_enrollment_classroom.student_enrollment.student }

    let!(:unique_daily_frequency_student) {
      create(
        :unique_daily_frequency_student,
        classroom: classroom,
        student: student,
        frequency_date: frequency_date,
        present: false
      )
    }

    subject(:notifier) { described_class.new }

    def students_with_absences
      notifier.send(:students_with_absences, classroom.id, start_at)
    end

    context 'when the student still belongs to the classroom' do
      it 'keeps the student in the classroom notification scope' do
        expect(students_with_absences).to contain_exactly(student.id)
      end
    end

    context 'when the student left the classroom but is active in another one' do
      before do
        student_enrollment_classroom.update_attribute(:left_at, Date.yesterday - 1)
        create(:classroom, :with_student_enrollment_classroom, student: student)
      end

      it 'does not notify the classroom the student already left' do
        expect(students_with_absences).to eq([])
      end
    end

    context 'when the student left the classroom and is not enrolled anywhere' do
      before { student_enrollment_classroom.update_attribute(:left_at, Date.yesterday - 1) }

      it 'notifies the origin classroom so the notification is not lost' do
        expect(students_with_absences).to contain_exactly(student.id)
      end
    end
  end
end
