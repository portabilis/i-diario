require 'rails_helper'

RSpec.describe AttendanceRecordReportByStudentForm, type: :model do
  let(:unity) { create(:unity) }
  let(:classroom) { create(:classroom, year: '2023', unity: unity) }
  let(:school_calendar) { create(:school_calendar, unity: unity) }
  let(:school_calendar_year) { school_calendar.year }
  let(:current_user_admin) { create(:user, :with_user_role_administrator) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:school_calendar_year) }
    it { is_expected.to validate_presence_of(:school_calendar) }
    it { is_expected.to validate_presence_of(:current_user_id) }
    it { is_expected.to validate_presence_of(:classroom_id) }
    it { is_expected.to validate_presence_of(:unity_id) }
    it { is_expected.to validate_presence_of(:period) }
    it { is_expected.to validate_presence_of(:start_at) }
    it { is_expected.to validate_presence_of(:end_at) }

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

        is_expected.to_not be_valid
        expect(subject.errors.messages[:start_at]).to include('não pode ser maior que a Data final')
        expect(subject.errors.messages[:end_at]).to include('deve ser maior ou igual a Data inicial')
      end
    end
  end

  describe 'methods' do
    describe '#filename' do
      it 'returns a filename with the current timestamp and .pdf extension' do
        frozen_time = Time.new(2024, 2, 8, 12, 0, 0)

        Timecop.freeze(frozen_time) do
          report = AttendanceRecordReportByStudentForm.new()
          filename = report.filename
          expect(filename).to eq("#{frozen_time.to_i}.pdf")
        end
      end
    end

    describe '#unity' do
      context 'when unity_id param is present' do
        it 'returns a unity' do
          report = AttendanceRecordReportByStudentForm.new(unity_id: unity.id)

          expect(report.unity).to eq(unity)
        end
      end

      context 'when unity_id param is not present' do
        it 'return nil' do
          report = AttendanceRecordReportByStudentForm.new(unity_id: nil)

          expect(report.unity).to eq(nil)
        end
      end
    end
  end
end
