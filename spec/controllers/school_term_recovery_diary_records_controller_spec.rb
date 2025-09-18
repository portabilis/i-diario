require 'rails_helper'

RSpec.describe SchoolTermRecoveryDiaryRecordsController, type: :controller do
  let(:current_user) { create(:user) }
  let(:teacher) { create(:teacher) }
  let(:classroom) { create(:classroom, :with_classroom_semester_steps) }
  let(:discipline) { create(:discipline) }
  let(:unity) { classroom.unity }

  before do
    sign_in(current_user)
    allow(controller).to receive(:current_user_classroom).and_return(classroom)
    allow(controller).to receive(:current_user_discipline).and_return(discipline)
    allow(controller).to receive(:current_teacher).and_return(teacher)
    allow(controller).to receive(:current_unity).and_return(unity)
  end

  describe '#test_setting' do
    context 'when teacher has multiple classrooms with different evaluation rules' do
      let(:recovery_classroom) do
        create(
          :classroom,
          :with_classroom_semester_steps,
          :score_type_numeric_and_concept_create_rule,
          :with_student_enrollment_classroom
        )
      end

      let(:recovery_diary_record) do
        create(
          :recovery_diary_record,
          :with_teacher_discipline_classroom,
          :with_students,
          classroom: recovery_classroom,
          discipline: discipline,
          teacher: teacher
        )
      end

      let(:school_term_recovery_diary_record) do
        create(:school_term_recovery_diary_record, recovery_diary_record: recovery_diary_record)
      end

      before do
        create(:teacher_discipline_classroom, teacher: teacher, classroom: recovery_classroom, discipline: discipline)

        controller.instance_variable_set(:@school_term_recovery_diary_record, school_term_recovery_diary_record)
      end

      it 'uses the classroom from the recovery record instead of current user classroom' do
        step = school_term_recovery_diary_record.step

        expect(TestSettingFetcher).to receive(:current).with(recovery_classroom, step)
        expect { controller.send(:test_setting) }.not_to raise_error
      end
    end
  end
end
