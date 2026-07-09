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

  describe '#classrooms_with_absences' do
    subject(:notifier) { described_class.new }

    # A busca considera o intervalo beginning_of_year..ontem, então a falta precisa ser <= ontem.
    let(:frequency_date) { Date.yesterday }

    def absence_in(classroom)
      create(
        :unique_daily_frequency_student,
        classroom: classroom,
        student: create(:student),
        frequency_date: frequency_date,
        present: false
      )
    end

    def classrooms_with_absences
      notifier.send(:classrooms_with_absences).to_a
    end

    it 'returns each classroom with absences exactly once, even with several absence rows' do
      classroom = create(:classroom)
      3.times { absence_in(classroom) }

      expect(classrooms_with_absences.map(&:id)).to contain_exactly(classroom.id)
    end

    it 'ignores classrooms that only have present records (no absences)' do
      classroom_with_absence = create(:classroom)
      classroom_present_only = create(:classroom)
      absence_in(classroom_with_absence)
      create(
        :unique_daily_frequency_student,
        classroom: classroom_present_only,
        student: create(:student),
        frequency_date: frequency_date,
        present: true
      )

      expect(classrooms_with_absences.map(&:id)).to contain_exactly(classroom_with_absence.id)
    end

    it 'excludes discarded (soft-deleted) classrooms' do
      kept_classroom = create(:classroom)
      discarded_classroom = create(:classroom)
      absence_in(kept_classroom)
      absence_in(discarded_classroom)
      discarded_classroom.discard

      expect(classrooms_with_absences.map(&:id)).to contain_exactly(kept_classroom.id)
    end
  end

  describe '#alternating_absences?' do
    subject(:notifier) { described_class.new }

    before do
      allow(notifier).to receive(:general_configuration)
        .and_return(double('general_configuration', max_alternate_absence_days: 7))
    end

    # Aluno em mais de uma turma pode ter a mesma data de falta repetida (um registro por turma).
    # O mesmo dia deve contar uma vez só — senão dispara alternadas com menos dias que o limite.
    it 'counts each day once when the same absence date comes from more than one classroom' do
      dates = [8, 8, 9, 9, 10, 10, 11, 11, 12, 12].map { |day| Date.new(2026, 6, day) }

      expect(notifier.send(:alternating_absences?, dates)).to eq(false)
    end

    it 'notifies when the number of distinct days reaches the limit' do
      dates = (1..7).map { |day| Date.new(2026, 6, day) }

      expect(notifier.send(:alternating_absences?, dates)).to eq(true)
    end
  end

  describe '#consecutive_absences?' do
    subject(:notifier) { described_class.new }

    before do
      allow(notifier).to receive(:general_configuration)
        .and_return(double('general_configuration', max_consecutive_absence_days: 5))
    end

    # os 5 últimos dias letivos até ontem (a sequência esperada)
    let(:school_dates) do
      [Date.new(2026, 6, 25), Date.new(2026, 6, 26), Date.new(2026, 6, 29), Date.new(2026, 6, 30), Date.new(2026, 7, 1)]
    end

    # Sem o dedupe, as datas repetidas (uma por turma) quebrariam a comparação e a sequência
    # deixaria de ser reconhecida — este teste falha sem o .uniq.
    it 'recognizes the streak even when the same date comes from more than one classroom' do
      absence_dates = [
        Date.new(2026, 6, 25), Date.new(2026, 6, 25),
        Date.new(2026, 6, 26), Date.new(2026, 6, 26),
        Date.new(2026, 6, 29), Date.new(2026, 6, 29),
        Date.new(2026, 6, 30), Date.new(2026, 6, 30),
        Date.new(2026, 7, 1),  Date.new(2026, 7, 1)
      ]

      expect(notifier.send(:consecutive_absences?, school_dates, absence_dates)).to eq(true)
    end
  end
end
