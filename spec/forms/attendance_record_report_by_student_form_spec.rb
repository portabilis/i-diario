require 'rails_helper'

RSpec.describe AttendanceRecordReportByStudentForm, type: :model do
  let(:unity) { create(:unity) }
  let(:classroom) { create(:classroom, year: '2023', unity: unity) }
  let(:school_calendar) { create(:school_calendar, unity: unity) }
  let(:school_calendar_year) { school_calendar.year }
  let(:current_user_admin) { create(:user, :with_user_role_administrator) }

  describe 'validations' do
    it { is_expect.to validate_presence_of(:school_calendar_year) }
    it { is_expect.to validate_presence_of(:school_calendar) }
    it { is_expect.to validate_presence_of(:current_user_id) }
    it { is_expect.to validate_presence_of(:classroom_id) }
    it { is_expect.to validate_presence_of(:unity_id) }
    it { is_expect.to validate_presence_of(:period) }
    it { is_expect.to validate_presence_of(:start_at) }
    it { is_expect.to validate_presence_of(:end_at) }

    context 'when end_at is lower than start_at' do
      subject(:attendance_record_report_by_student_form) {
        AttendanceRecordReportByStudentForm.new(
          unity_id: unity.id,
          classroom_id: classroom.id,
          period: Periods::MATUTINAL,
          school_calendar_year: school_calendar_year,
          school_calendar: school_calendar,
          current_user_id: current_user_admin.id,
        )
      }

      it 'return error message' do
        subject.start_at = '2023-02-02'
        subject.end_at = '2023-01-01'

        is_expect.to_not be_valid
        expect(subject.errors.messages[:start_at]).to include('não pode ser maior que a Data final')
        expect(subject.errors.messages[:end_at]).to include('deve ser maior ou igual a Data inicial')
      end
    end
  end
end
