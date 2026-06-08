# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DailyNotesController, 'duplicate enrollments check' do
  let(:controller) { DailyNotesController.new }
  let(:daily_note) { instance_double(DailyNote, test_date: Date.new(2026, 4, 29)) }
  let(:flash) { ActionDispatch::Flash::FlashHash.new }

  before do
    controller.instance_variable_set(:@daily_note, daily_note)
    allow(controller).to receive(:flash).and_return(flash)
    allow(controller).to receive(:set_enrollment_classrooms).and_return(enrollments)
  end

  let(:students_cache) { {} }

  def build_student(student_id, student_name)
    students_cache[student_id] ||= instance_double(Student, id: student_id, name: student_name)
  end

  # Helper para montar o hash retornado pelo StudentEnrollmentClassroomsRetriever
  def build_enrollment(student_id:, student_name: "Aluno #{student_id}", status: 3, active: 1, left_at: nil)
    student = build_student(student_id, student_name)
    student_enrollment = instance_double(StudentEnrollment, status: status, active: active)
    student_enrollment_classroom = instance_double(StudentEnrollmentClassroom, left_at: left_at)

    {
      student: student,
      student_enrollment: student_enrollment,
      student_enrollment_classroom: student_enrollment_classroom
    }
  end

  context 'when there are no duplicate enrollments' do
    let(:enrollments) do
      [
        build_enrollment(student_id: 1),
        build_enrollment(student_id: 2),
        build_enrollment(student_id: 3)
      ]
    end

    it 'does not set flash error' do
      controller.send(:check_duplicate_enrolled_students)

      expect(flash[:error]).to be_nil
    end
  end

  context 'when the same student appears twice with both enrollments fully open (no left_at)' do
    let(:enrollments) do
      [
        build_enrollment(student_id: 31151, student_name: 'MANUELLA BARBOSA', left_at: nil),
        build_enrollment(student_id: 31151, student_name: 'MANUELLA BARBOSA', left_at: nil),
        build_enrollment(student_id: 2)
      ]
    end

    it 'sets flash error with the duplicated student name' do
      controller.send(:check_duplicate_enrolled_students)

      expect(flash[:error]).to eq(
        I18n.t('daily_notes.duplicate_students', students: 'MANUELLA BARBOSA')
      )
    end
  end

  context 'when the same student has overlapping enrollments (one with future left_at, one open)' do
    let(:enrollments) do
      [
        build_enrollment(student_id: 31151, student_name: 'MANUELLA BARBOSA', left_at: Date.new(2026, 5, 28)),
        build_enrollment(student_id: 31151, student_name: 'MANUELLA BARBOSA', left_at: nil),
        build_enrollment(student_id: 2)
      ]
    end

    it 'sets flash error with the duplicated student name' do
      controller.send(:check_duplicate_enrolled_students)

      expect(flash[:error]).to eq(
        I18n.t('daily_notes.duplicate_students', students: 'MANUELLA BARBOSA')
      )
    end
  end

  context 'when one enrollment was closed before test_date and another is still active' do
    let(:enrollments) do
      [
        build_enrollment(student_id: 31151, left_at: Date.new(2026, 4, 18)),
        build_enrollment(student_id: 31151, left_at: nil)
      ]
    end

    it 'does not set flash error' do
      controller.send(:check_duplicate_enrolled_students)

      expect(flash[:error]).to be_nil
    end
  end

  context 'when one enrollment has left_at exactly equal to test_date' do
    let(:enrollments) do
      [
        build_enrollment(student_id: 31151, student_name: 'MANUELLA BARBOSA', left_at: Date.new(2026, 4, 29)),
        build_enrollment(student_id: 31151, student_name: 'MANUELLA BARBOSA', left_at: nil)
      ]
    end

    it 'sets flash error with the duplicated student name' do
      controller.send(:check_duplicate_enrolled_students)

      expect(flash[:error]).to eq(
        I18n.t('daily_notes.duplicate_students', students: 'MANUELLA BARBOSA')
      )
    end
  end

  context 'when left_at is a String (as returned by sync data)' do
    let(:enrollments) do
      [
        build_enrollment(student_id: 31151, student_name: 'MANUELLA BARBOSA', left_at: '2026-05-28'),
        build_enrollment(student_id: 31151, student_name: 'MANUELLA BARBOSA', left_at: '')
      ]
    end

    it 'parses the string and detects the duplicate' do
      controller.send(:check_duplicate_enrolled_students)

      expect(flash[:error]).to eq(
        I18n.t('daily_notes.duplicate_students', students: 'MANUELLA BARBOSA')
      )
    end
  end
end
