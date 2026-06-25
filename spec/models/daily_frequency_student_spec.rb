# encoding: utf-8
require 'rails_helper'

RSpec.describe DailyFrequencyStudent, :type => :model do
  describe "associations" do
    it { should belong_to :daily_frequency }
    it { should belong_to :student }
  end

  describe "validations" do
    it { should validate_presence_of :student }
    it { should validate_presence_of :daily_frequency }
  end

  # Ao persistir a frequência, o status "active" é derivado de #student_enrollment_classroom:
  # aluno fora da janela de matrícula (ex.: já transferido) entra como inativo, o que zera a
  # presença e evita que vire falta de infrequência.
  describe "#student_enrollment_classroom drives the active flag on persistence" do
    let!(:classroom) {
      create(:classroom, :with_student_enrollment_classroom, :with_classroom_semester_steps)
    }
    let(:student_enrollment_classroom) { classroom.student_enrollment_classrooms.first }
    let(:student) { student_enrollment_classroom.student_enrollment.student }
    let(:daily_frequency) { create(:daily_frequency, classroom: classroom, frequency_date: Date.current) }

    def persist_with_active_from_enrollment
      daily_frequency_student = DailyFrequencyStudent.find_or_initialize_by(
        daily_frequency_id: daily_frequency.id,
        student_id: student.id
      )
      daily_frequency_student.present = false
      daily_frequency_student.active = daily_frequency_student.student_enrollment_classroom.present?
      daily_frequency_student.save!
      daily_frequency_student.reload
    end

    context "when the student is enrolled in the classroom on the frequency date" do
      it "persists the frequency as active" do
        expect(persist_with_active_from_enrollment.active).to eq(true)
      end
    end

    context "when the student already left the classroom before the frequency date" do
      before { student_enrollment_classroom.update_attribute(:left_at, daily_frequency.frequency_date - 1) }

      it "persists the frequency as inactive" do
        expect(persist_with_active_from_enrollment.active).to eq(false)
      end

      it "nullifies the presence of the inactive record" do
        expect(persist_with_active_from_enrollment.present).to be_nil
      end
    end
  end
end
