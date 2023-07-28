require 'rails_helper'

RSpec.describe DailyNoteCreator, type: :service do
  before(:each) do
    SchoolCalendarDayValidator.any_instance.stub(:validate_each).and_return(true)
  end

  let(:classroom) { create(:classroom, :score_type_numeric) }
  let(:avaliation) {
    create(
      :avaliation,
      :with_teacher_discipline_classroom,
      classroom: classroom
    )
  }

  it 'create daily note when avaliation is passed by parameter' do
    creator = described_class.new(
      avaliation_id: avaliation.id
    )

    expect { creator.find_or_create }.to change { DailyNote.count }.to(1)
  end

  context 'exist student enrollments' do
    let(:student_enrollment) { create(:student_enrollment) }

    before do
      StudentEnrollmentClassroom.create!(
        classrooms_grade: classroom.classrooms_grades.first,
        student_enrollment: student_enrollment,
        joined_at: Date.current.beginning_of_year,
        left_at: ''
      )
    end

    it 'create daily note students' do
      StudentEnrollmentsList.any_instance.stub(:student_enrollments).and_return([student_enrollment])
      creator = described_class.new(
        avaliation_id: avaliation.id
      )

      expect { creator.find_or_create }.to change { DailyNoteStudent.count }.to(1)
    end
  end
end
