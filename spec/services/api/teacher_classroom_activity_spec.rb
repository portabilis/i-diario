require 'rails_helper'

RSpec.describe Api::TeacherClassroomActivity do
  let(:teacher) { create(:teacher) }
  let(:classroom) { create(:classroom, :with_classroom_semester_steps) }
  let(:user) { create(:user, teacher: teacher) }

  subject { described_class.new(teacher.id, classroom.id) }

  around(:each) do |example|
    Entity.find_by_domain("test.host").using_connection do
      example.run
    end
  end

  describe '#any_activity?' do
    context 'when there is no user for the teacher' do
      before do
        teacher.update!(id: 999999) # ID that has no associated user
      end

      it 'returns false' do
        activity_checker = described_class.new(999999, classroom.id)
        expect(activity_checker.any_activity?).to be false
      end
    end

    context 'when there is a user for the teacher' do
      before do
        user # Ensure the user exists
      end

      context 'and there are no activities' do
        it 'returns false' do
          expect(subject.any_activity?).to be false
        end
      end

      context 'and there is a DailyNote' do
        let!(:avaliation) do
          create(
            :avaliation,
            :with_teacher_discipline_classroom,
            classroom: classroom,
            teacher: teacher,
            school_calendar: classroom.calendar.school_calendar,
            test_date: Date.current
          )
        end
        let!(:daily_note) { create(:daily_note, avaliation: avaliation) }

        before do
          # Simulate DailyNote audit
          allow(DailyNote).to receive_message_chain(:by_classroom_id, :by_teacher_id, :joins, :where, :exists?)
            .and_return(true)
        end

        it 'returns true' do
          expect(subject.any_activity?).to be true
        end
      end

      context 'and there is a DailyFrequency' do
        before do
          allow(DailyNote).to receive_message_chain(:by_classroom_id, :by_teacher_id, :joins, :where, :exists?)
            .and_return(false)
          allow(DailyFrequency).to receive_message_chain(:by_classroom_id, :by_teacher_classroom_id, :joins, :where, :exists?)
            .and_return(true)
        end

        it 'returns true' do
          expect(subject.any_activity?).to be true
        end
      end

      context 'and there is a ConceptualExam' do
        before do
          allow(DailyNote).to receive_message_chain(:by_classroom_id, :by_teacher_id, :joins, :where, :exists?)
            .and_return(false)
          allow(DailyFrequency).to receive_message_chain(:by_classroom_id, :by_teacher_classroom_id, :joins, :where, :exists?)
            .and_return(false)
          allow(ConceptualExam).to receive_message_chain(:by_classroom_id, :by_teacher, :joins, :where, :exists?)
            .and_return(true)
        end

        it 'returns true' do
          expect(subject.any_activity?).to be true
        end
      end

      context 'and there is a DescriptiveExam' do
        before do
          allow(DailyNote).to receive_message_chain(:by_classroom_id, :by_teacher_id, :joins, :where, :exists?)
            .and_return(false)
          allow(DailyFrequency).to receive_message_chain(:by_classroom_id, :by_teacher_classroom_id, :joins, :where, :exists?)
            .and_return(false)
          allow(ConceptualExam).to receive_message_chain(:by_classroom_id, :by_teacher, :joins, :where, :exists?)
            .and_return(false)
          allow(DescriptiveExam).to receive_message_chain(:by_classroom_id, :by_teacher_id, :joins, :where, :exists?)
            .and_return(true)
        end

        it 'returns true' do
          expect(subject.any_activity?).to be true
        end
      end

      context 'and there is a RecoveryDiaryRecord' do
        before do
          allow(DailyNote).to receive_message_chain(:by_classroom_id, :by_teacher_id, :joins, :where, :exists?)
            .and_return(false)
          allow(DailyFrequency).to receive_message_chain(:by_classroom_id, :by_teacher_classroom_id, :joins, :where, :exists?)
            .and_return(false)
          allow(ConceptualExam).to receive_message_chain(:by_classroom_id, :by_teacher, :joins, :where, :exists?)
            .and_return(false)
          allow(DescriptiveExam).to receive_message_chain(:by_classroom_id, :by_teacher_id, :joins, :where, :exists?)
            .and_return(false)
          allow(RecoveryDiaryRecord).to receive_message_chain(:by_classroom_id, :by_teacher_id, :joins, :where, :exists?)
            .and_return(true)
        end

        it 'returns true' do
          expect(subject.any_activity?).to be true
        end
      end

      context 'and there is a TransferNote' do
        before do
          allow(DailyNote).to receive_message_chain(:by_classroom_id, :by_teacher_id, :joins, :where, :exists?)
            .and_return(false)
          allow(DailyFrequency).to receive_message_chain(:by_classroom_id, :by_teacher_classroom_id, :joins, :where, :exists?)
            .and_return(false)
          allow(ConceptualExam).to receive_message_chain(:by_classroom_id, :by_teacher, :joins, :where, :exists?)
            .and_return(false)
          allow(DescriptiveExam).to receive_message_chain(:by_classroom_id, :by_teacher_id, :joins, :where, :exists?)
            .and_return(false)
          allow(RecoveryDiaryRecord).to receive_message_chain(:by_classroom_id, :by_teacher_id, :joins, :where, :exists?)
            .and_return(false)
          allow(TransferNote).to receive_message_chain(:by_classroom_id, :by_teacher_id, :joins, :where, :exists?)
            .and_return(true)
        end

        it 'returns true' do
          expect(subject.any_activity?).to be true
        end
      end

      context 'and there is a ComplementaryExam' do
        before do
          allow(DailyNote).to receive_message_chain(:by_classroom_id, :by_teacher_id, :joins, :where, :exists?)
            .and_return(false)
          allow(DailyFrequency).to receive_message_chain(:by_classroom_id, :by_teacher_classroom_id, :joins, :where, :exists?)
            .and_return(false)
          allow(ConceptualExam).to receive_message_chain(:by_classroom_id, :by_teacher, :joins, :where, :exists?)
            .and_return(false)
          allow(DescriptiveExam).to receive_message_chain(:by_classroom_id, :by_teacher_id, :joins, :where, :exists?)
            .and_return(false)
          allow(RecoveryDiaryRecord).to receive_message_chain(:by_classroom_id, :by_teacher_id, :joins, :where, :exists?)
            .and_return(false)
          allow(TransferNote).to receive_message_chain(:by_classroom_id, :by_teacher_id, :joins, :where, :exists?)
            .and_return(false)
          allow(ComplementaryExam).to receive_message_chain(:by_classroom_id, :by_teacher_id, :joins, :where, :exists?)
            .and_return(true)
        end

        it 'returns true' do
          expect(subject.any_activity?).to be true
        end
      end
    end
  end

  describe '#join_audits' do
    it 'returns correct SQL for join with audits' do
      sql = subject.send(:join_audits, 'test_table.id', 'TestModel')

      expected_sql = <<-SQL
        INNER JOIN audits
          ON audits.auditable_id = test_table.id AND audits.auditable_type = 'TestModel'
      SQL

      expect(sql.strip).to eq(expected_sql.strip)
    end
  end
end
