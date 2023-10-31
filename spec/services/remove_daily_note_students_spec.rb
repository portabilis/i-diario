require 'spec_helper'

RSpec.describe RemoveDailyNoteStudents, type: :service do
  let!(:school_calendar) {
    create(
      :school_calendar,
      :with_trimester_steps
    )
  }
  let(:classroom) { create(:classroom, unity: school_calendar.unity) }
  let(:classroom_grades) { create(:classrooms_grade, classroom: classroom) }
  let(:teacher_discipline_classroom) {
    create(
      :teacher_discipline_classroom,
      classroom: classroom
    )
  }
  let(:avaliation) {
    create(
      :avaliation,
      school_calendar: school_calendar,
      classroom: classroom,
      discipline: teacher_discipline_classroom.discipline,
      teacher_id: teacher_discipline_classroom.teacher.id
    )
  }
  let(:daily_note) { create(:daily_note, avaliation: avaliation) }
  let(:student_enrollment) { create(:student_enrollment) }
  let(:student_enrollment_classroom) {
    create(
      :student_enrollment_classroom,
      student_enrollment: student_enrollment,
      classrooms_grade: classroom_grades,
      left_at: '2017-04-04',
      joined_at: '2017-03-01'
    )
  }
  let(:transfer_note) {
    create(
      :transfer_note,
      classroom: classroom,
      teacher: teacher_discipline_classroom.teacher,
      discipline_id: teacher_discipline_classroom.discipline_id,
      student: student_enrollment.student,
      unity_id: school_calendar.unity.id,
      step_number: school_calendar.steps.first.step_number
    )
  }
  let(:daily_note_student) {
    create(
      :daily_note_student,
      daily_note: daily_note,
      transfer_note: transfer_note,
      student: student_enrollment.student,
      note: 10
    )
  }

  subject do
    RemoveDailyNoteStudents.call(
      student_enrollment_classroom.joined_at,
      student_enrollment_classroom.left_at,
      student_enrollment.student_id,
      classroom_grades.classroom_id
    )
  end

  describe 'when a student has a note OR transfer_note' do
    context 'and is enrolled on the date' do
      it 'should return an empty array, no modifications made' do
        expect(subject).to eq []
      end
    end

    context 'and is NOT in enrolled on the date' do
      it 'should return an empty array, no modifications made' do
        student_enrollment_classroom.update(left_at: '2017-02-25')
        expect(subject).to eq []
      end
    end
  end

  describe 'when a student does NOT have note OR transfer note' do
    before { daily_note_student.update(note: nil, transfer_note: nil) }

    context 'and is enrolled on the date' do
      it 'should return an array with daily_note_student without modification' do
        expect(subject).to eq [daily_note_student]
      end
    end

    context 'and is NOT in enrolled on the date' do
      it 'should return an array with daily_note_student with discarded' do
        student_enrollment_classroom.update(left_at: '2017-02-25')

        expect(subject.map(&:discarded?)).to eq [true]
      end
    end
  end
end
