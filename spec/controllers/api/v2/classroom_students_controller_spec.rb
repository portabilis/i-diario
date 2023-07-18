require 'rails_helper'

RSpec.describe Api::V2::ClassroomStudentsController, type: :controller do
  describe 'GET #index' do
    let(:classroom) { create(:classroom) }
    let(:discipline) { create(:discipline) }

    around(:each) do |example|
      Entity.find_by_domain("test.host").using_connection do
        example.run
      end
    end

    before do
      request.env['REQUEST_PATH'] = '/api/v2/classroom_students'
    end

    it 'returns no student when does not have calendar' do
      params = {
        classroom_id: classroom.id,
        discipline_id: discipline.id,
        format: "json",
        locale: "en"
      }

      expect { get :index, params: params, xhr: true }.to_not raise_error

      json = ActiveSupport::JSON.decode(response.body)

      expect(json).to eq({ "classroom_students" => [] })
    end

    it 'returns students when has school calender and enrollments' do
      student_enrollment_classroom = create(:student_enrollment_classroom)
      school_calendar = create(:school_calendar, :with_one_step, unity: student_enrollment_classroom.classrooms_grade.classroom.unity)
      frequency_start_at = Date.parse("#{school_calendar.year}-01-01")

      student_enrollment_classroom.update_attribute(:joined_at, frequency_start_at)

      params = {
        classroom_id: student_enrollment_classroom.classrooms_grade.classroom.id,
        discipline_id: discipline.id,
        format: "json",
        locale: "en",
        frequency_date: 1.business_days.after(frequency_start_at)
      }

      expect { get :index, params: params, xhr: true }.to_not raise_error
      json = ActiveSupport::JSON.decode(response.body)

      expect(json["classroom_students"].first["id"]).
        to eq(student_enrollment_classroom.student_enrollment.id)
    end
  end
end
