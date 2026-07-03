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

  # enrolled_in_classroom? indica se o aluno tem matrícula válida na turma na data da frequência.
  # É o método usado pela API v2 para derivar o status "active" ao gravar a frequência: aluno
  # fora da janela (ex.: já transferido) entra inativo, o que zera a presença e evita que vire
  # falta de infrequência (a infrequência só considera registros com active = true).
  describe "#enrolled_in_classroom?" do
    let!(:classroom) {
      create(:classroom, :with_student_enrollment_classroom, :with_classroom_semester_steps)
    }
    let(:student_enrollment_classroom) { classroom.student_enrollment_classrooms.first }
    let(:student) { student_enrollment_classroom.student_enrollment.student }
    let(:daily_frequency) { create(:daily_frequency, classroom: classroom, frequency_date: Date.current) }
    let(:daily_frequency_student) {
      DailyFrequencyStudent.new(daily_frequency: daily_frequency, student_id: student.id)
    }

    context "when the student is enrolled in the classroom on the frequency date" do
      it "returns true" do
        expect(daily_frequency_student.enrolled_in_classroom?).to eq(true)
      end
    end

    context "when the student already left the classroom before the frequency date" do
      before { student_enrollment_classroom.update_attribute(:left_at, daily_frequency.frequency_date - 1) }

      it "returns false" do
        expect(daily_frequency_student.enrolled_in_classroom?).to eq(false)
      end

      it "persists the record as inactive and nullifies the presence" do
        daily_frequency_student.present = false
        daily_frequency_student.active = daily_frequency_student.enrolled_in_classroom?
        daily_frequency_student.save!

        expect(daily_frequency_student.reload).to have_attributes(active: false, present: nil)
      end
    end
  end
end
