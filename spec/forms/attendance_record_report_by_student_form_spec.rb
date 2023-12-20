require 'rails_helper'

RSpec.describe AttendanceRecordReportByStudentForm, type: :model do
  let(:unity) { create(:unity) }
  let(:classroom) { create(:classroom, year: '2023', unity: unity) }
  let(:school_calendar) { create(:school_calendar, unity: unity) }
  let(:school_calendar_year) { school_calendar.year }
  let(:current_user_admin) { create(:user, :with_user_role_administrator) }

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:school_calendar_year) }
    it { expect(subject).to validate_presence_of(:school_calendar) }
    it { expect(subject).to validate_presence_of(:current_user_id) }
    it { expect(subject).to validate_presence_of(:classroom_id) }
    it { expect(subject).to validate_presence_of(:unity_id) }
    it { expect(subject).to validate_presence_of(:period) }
    it { expect(subject).to validate_presence_of(:start_at) }
    it { expect(subject).to validate_presence_of(:end_at) }

    context 'should validate if date end is lower than today' do
      subject(:attendance_record_report_by_student_form) {
        AttendanceRecordReportByStudentForm.new(
          unity_id: unity.id,
          classroom_id: classroom.id

        )
      }
    end
    context "should validate if start_at isn't greater than date end" do
    end
  end
end
