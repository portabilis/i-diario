require 'rails_helper'

RSpec.describe AttendanceRecordReportByStudentForm, type: :model do
  let(:unity) { create(:unity) }
  let(:classroom) { create(:classroom, year: '2023', unity: unity) }
  let(:school_calendar) { create(:school_calendar, unity: unity) }
  let(:school_calendar_year) { school_calendar.year }
  let(:current_user_admin) { create(:user, :with_user_role_administrator) }
  let(:teacher) { create(:teacher) }
  let(:current_user_teacher) { create(:user, :with_user_role_teacher, teacher: teacher) }

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
        it 'return a unity' do
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

    describe '#current_user' do
      context 'when current_user_id param is present' do
        it 'return a current_user' do
          report = AttendanceRecordReportByStudentForm.new(current_user_id: current_user_admin.id)

          expect(report.current_user).to eq(current_user_admin)
        end
      end

      context 'when current_user_id param is not present' do
        it 'return nil' do
          report = AttendanceRecordReportByStudentForm.new(current_user_id: nil)

          expect(report.current_user).to eq(nil)
        end
      end
    end

    describe '#select_all_classrooms' do
      let!(:other_unity) { create(:unity) }
      let!(:classrooms) { create_list(:classroom, 3, year: '2023', unity: unity) }
      let!(:teacher_discipline_classrooms) {
        create(
          :teacher_discipline_classroom,
          year: '2023',
          classroom: classroom,
          teacher: teacher
        )
      }

      context "when classroom_id param is not equal to 'all'" do
        it 'return only one classroom' do
          report = AttendanceRecordReportByStudentForm.new(classroom_id: classroom.id)
          expect(report.select_all_classrooms).to eq([classroom])
        end
      end

      context "when classroom_id param is equal to 'all' and current_user is admin?" do
        it 'returns linked classrooms at unity' do
          report = AttendanceRecordReportByStudentForm.new(
            unity_id: unity.id,
            classroom_id: 'all',
            current_user_id: current_user_admin.id
          )

          expect(report.select_all_classrooms).to eq(classrooms)
        end
      end

      context "when classroom_id param is equal to 'all' and current_user is teacher?" do
        it 'return linked classrooms at teacher' do
          report = AttendanceRecordReportByStudentForm.new(
            unity_id: unity.id,
            classroom_id: 'all',
            current_user_id: current_user_teacher.id
          )

          expect(report.select_all_classrooms).to eq([classroom])
        end
      end
    end
  end
end
