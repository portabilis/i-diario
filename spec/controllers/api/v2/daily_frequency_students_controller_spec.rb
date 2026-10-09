require 'rails_helper'

RSpec.describe Api::V2::DailyFrequencyStudentsController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:user) { create(:user) }
  let(:teacher) { create(:teacher) }
  let(:discipline) { create(:discipline) }
  let(:classroom) { create(:classroom, :with_classroom_semester_steps) }
  let!(:teacher_discipline_classroom) do
    create(:teacher_discipline_classroom, classroom: classroom, discipline: discipline, teacher: teacher)
  end
  let(:daily_frequency) do
    create(:daily_frequency, :with_students, classroom: classroom, discipline: discipline, teacher: teacher)
  end
  let(:daily_frequency_student) { daily_frequency.students.first }

  around do |example|
    entity.using_connection { example.run }
  end

  before do
    allow(controller).to receive(:authenticate_api!)
  end

  describe 'PUT #update' do
    it 'enqueues the automatic absence posting on behalf of the diary owner' do
      expect(AutomaticAbsencePostingEnqueuer).to receive(:call).with(
        entity_id: entity.id,
        classroom_id: classroom.id,
        frequency_dates: [daily_frequency.frequency_date],
        teacher_id: teacher.id
      )

      put :update, params: {
        id: daily_frequency_student.id,
        user_id: user.id,
        present: false,
        format: 'json',
        locale: 'en'
      }

      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #update_or_create' do
    before do
      allow(UniqueDailyFrequencyStudentsCreator).to receive(:call_worker)
      allow(AutomaticAbsencePostingEnqueuer).to receive(:call)
    end

    it 'creates the daily frequency when it does not exist yet' do
      classrooms_grade = create(:classrooms_grade, classroom: classroom)
      student = create(:student_enrollment_classroom, classrooms_grade: classrooms_grade).student_enrollment.student

      post :update_or_create, params: {
        user_id: user.id,
        teacher_id: teacher.id,
        classroom_id: classroom.id,
        discipline_id: discipline.id,
        class_number: 1,
        frequency_date: Date.current.to_s,
        student_id: student.id,
        present: false,
        format: 'json',
        locale: 'en'
      }

      expect(response).to have_http_status(:success)
      expect(response.body).not_to eq('[]')

      daily_frequency = DailyFrequency.find_by(
        classroom_id: classroom.id, discipline_id: discipline.id, class_number: 1
      )

      expect(daily_frequency).to be_present
      expect(daily_frequency.unity_id).to eq(classroom.unity_id)
      expect(daily_frequency.owner_teacher_id).to eq(teacher.id)
      expect(daily_frequency.students.pluck(:student_id, :present, :active)).to eq([[student.id, false, true]])
    end
  end
end
