require 'rails_helper'

RSpec.describe SchoolCalendarsUpdater, type: :service do
  describe '#update!' do
    context 'when there is update to school_calendar_steps' do
      let!(:classroom) { create(:classroom_numeric_and_concept) }
      let!(:school_calendar) { create(:school_calendar, :school_calendar_with_semester_steps, :current) }
      let(:conceptual_exam) { create(:conceptual_exam_with_one_value, school_calendar_step: school_calendar.steps.last, classroom: classroom) }
      let(:descriptive_exam) { create(:descriptive_exam, school_calendar_step: school_calendar.steps.last, classroom: classroom) }
      let(:transfer_note) { create(:transfer_note, school_calendar_step: school_calendar.steps.last, classroom: classroom) }
      let(:recovery_diary_record) { create(:current_recovery_diary_record_with_students, classroom: classroom) }
      let(:school_term_recovery_diary_record) do
        create(
          :current_school_term_recovery_diary_record,
          school_calendar_step: school_calendar.steps.last,
          recovery_diary_record: recovery_diary_record
        )
      end

      it 'needs to delete one step' do
        school_calendars['steps'].first['end_at'] = Date.new(Date.today.year, 12, 31)
        school_calendars['steps'].last['_destroy'] = 'true'
        updater = SchoolCalendarsUpdater.new(school_calendars)

        expect(school_calendar.steps.count).to be(2)

        updater.update!

        expect(school_calendar.steps.count).to be(1)
      end

      it 'needs to move related items to other step' do
        school_calendars['steps'].first['end_at'] = Date.new(Date.today.year, 12, 31)
        school_calendars['steps'].last['_destroy'] = 'true'

        updater = SchoolCalendarsUpdater.new(school_calendars)

        Timecop.freeze(Date.today.year, 9, 1, 0, 0, 0) do
          school_calendar_step_id = school_calendar.steps.last.id

          expect(conceptual_exam.school_calendar_step_id).to eq(school_calendar_step_id)
          expect(descriptive_exam.school_calendar_step_id).to eq(school_calendar_step_id)
          expect(transfer_note.school_calendar_step_id).to eq(school_calendar_step_id)
          expect(school_term_recovery_diary_record.school_calendar_step_id).to eq(school_calendar_step_id)

          updater.update!

          school_calendar_step_id = school_calendar.steps.last.id

          expect(conceptual_exam.school_calendar_step_id).to eq(school_calendar_step_id)
          expect(descriptive_exam.school_calendar_step_id).to eq(school_calendar_step_id)
          expect(transfer_note.school_calendar_step_id).to eq(school_calendar_step_id)
          expect(school_term_recovery_diary_record.school_calendar_step_id).to eq(school_calendar_step_id)
        end
      end

      it 'needs to create a new inactivate step and move unrelated items' do
        school_calendars['steps'].first['end_at'] = Date.new(Date.today.year, 8, 31)
        school_calendars['steps'].last['start_at'] = Date.new(Date.today.year, 9, 2)
        school_calendars['steps'].last['start_date_for_posting'] = Date.new(Date.today.year, 9, 2)

        updater = SchoolCalendarsUpdater.new(school_calendars)

        Timecop.freeze(Date.today.year, 9, 1, 0, 0, 0) do
          conceptual_exam_step = conceptual_exam.school_calendar_step
          transfer_note_step = transfer_note.school_calendar_step
          school_term_recovery_diary_record_step = school_term_recovery_diary_record.school_calendar_step

          expect(conceptual_exam_step.active).to be true
          expect(transfer_note_step.active).to be true
          expect(school_term_recovery_diary_record_step.active).to be true

          updater.update!

          new_conceptual_exam_step = conceptual_exam.reload.school_calendar_step
          new_transfer_note_step = transfer_note.reload.school_calendar_step
          new_school_term_recovery_diary_record_step = school_term_recovery_diary_record.reload.school_calendar_step

          expect(new_conceptual_exam_step.active).to be false
          expect(new_transfer_note_step.active).to be false
          expect(new_school_term_recovery_diary_record_step.active).to be false

          expect(new_conceptual_exam_step.id).not_to eq(conceptual_exam_step.id)
          expect(new_transfer_note_step.id).not_to eq(transfer_note_step.id)
          expect(new_school_term_recovery_diary_record_step.id).not_to eq(school_term_recovery_diary_record_step.id)
        end
      end

      it 'needs to create a new inactivate step and move descriptive_exams' do
        school_calendars['steps'].first['end_at'] = Date.new(Date.today.year, 8, 31)
        school_calendars['steps'].last['start_at'] = Date.new(Date.today.year, 9, 1)
        school_calendars['steps'].last['start_date_for_posting'] = Date.new(Date.today.year, 9, 1)

        updater = SchoolCalendarsUpdater.new(school_calendars)

        school_calendar_step = school_calendar.steps.last

        expect(descriptive_exam.school_calendar_step_id).to eq(school_calendar_step.id)
        expect(descriptive_exam.school_calendar_step.active).to be true

        updater.update!

        school_calendar_step = school_calendar.steps.first
        descriptive_exam.reload

        expect(descriptive_exam.school_calendar_step_id).not_to eq(school_calendar_step.id)
        expect(descriptive_exam.school_calendar_step.active).to be false
      end

      def school_calendars
        @school_calendars ||= begin
          school_calendars = school_calendar.serializable_hash(include: :steps)
          school_calendars['school_calendar_id'] = school_calendars.delete('id')
          school_calendars['steps'].each { |item| item['_destroy'] = 'false' }
          school_calendars
        end
      end
    end

    context 'when there is update to school_calendar_classroom_steps' do
      let!(:classroom) { create(:classroom_numeric_and_concept) }
      let!(:school_calendar) { create(:school_calendar, :school_calendar_with_semester_steps, :current) }
      let!(:school_calendar_classroom) do
        create(
          :school_calendar_classroom,
          :school_calendar_classroom_with_semester_steps,
          school_calendar: school_calendar,
          classroom: classroom
        )
      end
      let(:conceptual_exam) do
        create(
          :conceptual_exam_with_one_value,
          school_calendar_step: nil,
          classroom: classroom,
          school_calendar_classroom_step: school_calendar_classroom.classroom_steps.last
        )
      end
      let(:descriptive_exam) do
        create(
          :descriptive_exam,
          school_calendar_step: nil,
          classroom: classroom,
          school_calendar_classroom_step: school_calendar_classroom.classroom_steps.last
        )
      end
      let(:transfer_note) do
        create(
          :transfer_note,
          school_calendar_step: nil,
          classroom: classroom,
          school_calendar_classroom_step: school_calendar_classroom.classroom_steps.last
        )
      end
      let(:recovery_diary_record) { create(:current_recovery_diary_record_with_students, classroom: classroom) }
      let(:school_term_recovery_diary_record) do
        create(
          :current_school_term_recovery_diary_record,
          school_calendar_step: nil,
          recovery_diary_record: recovery_diary_record,
          school_calendar_classroom_step: school_calendar_classroom.classroom_steps.last
        )
      end

      it 'needs to delete one classroom_step' do
        school_calendars['classrooms'].first['steps'].first['end_at'] = Date.new(Date.today.year, 12, 31)
        school_calendars['classrooms'].first['steps'].last['_destroy'] = 'true'
        updater = SchoolCalendarsUpdater.new(school_calendars)

        expect(school_calendar_classroom.classroom_steps.count).to be(2)

        updater.update!

        expect(school_calendar_classroom.classroom_steps.count).to be(1)
      end

      it 'needs to move related items to other classroom_step' do
        school_calendars['classrooms'].first['steps'].first['end_at'] = Date.new(Date.today.year, 12, 31)
        school_calendars['classrooms'].first['steps'].last['_destroy'] = 'true'

        updater = SchoolCalendarsUpdater.new(school_calendars)

        Timecop.freeze(Date.today.year, 9, 1, 0, 0, 0) do
          classroom_step_id = school_calendar_classroom.classroom_steps.last.id

          expect(conceptual_exam.school_calendar_classroom_step_id).to eq(classroom_step_id)
          expect(descriptive_exam.school_calendar_classroom_step_id).to eq(classroom_step_id)
          expect(transfer_note.school_calendar_classroom_step_id).to eq(classroom_step_id)
          expect(school_term_recovery_diary_record.school_calendar_classroom_step_id).to eq(classroom_step_id)

          updater.update!

          classroom_step_id = school_calendar_classroom.classroom_steps.first.id

          expect(conceptual_exam.reload.school_calendar_classroom_step_id).to eq(classroom_step_id)
          expect(descriptive_exam.reload.school_calendar_classroom_step_id).to eq(classroom_step_id)
          expect(transfer_note.reload.school_calendar_classroom_step_id).to eq(classroom_step_id)
          expect(school_term_recovery_diary_record.reload.school_calendar_classroom_step_id).to eq(classroom_step_id)
        end
      end

      it 'needs to create a new inactivate classroom_step and move unrelated items' do
        school_calendars['classrooms'].first['steps'].first['end_at'] = Date.new(Date.today.year, 8, 31)
        school_calendars['classrooms'].first['steps'].last['start_at'] = Date.new(Date.today.year, 9, 2)
        school_calendars['classrooms'].first['steps'].last['start_date_for_posting'] = Date.new(Date.today.year, 9, 2)

        updater = SchoolCalendarsUpdater.new(school_calendars)

        Timecop.freeze(Date.today.year, 9, 1, 0, 0, 0) do
          conceptual_exam_step = conceptual_exam.school_calendar_classroom_step
          transfer_note_step = transfer_note.school_calendar_classroom_step
          school_term_recovery_diary_record_step = school_term_recovery_diary_record.school_calendar_classroom_step

          expect(conceptual_exam_step.active).to be true
          expect(transfer_note_step.active).to be true
          expect(school_term_recovery_diary_record_step.active).to be true

          updater.update!

          new_conceptual_exam_step = conceptual_exam.reload.school_calendar_classroom_step
          new_transfer_note_step = transfer_note.reload.school_calendar_classroom_step
          new_school_term_recovery_diary_record_step = school_term_recovery_diary_record.reload.school_calendar_classroom_step

          expect(new_conceptual_exam_step.active).to be false
          expect(new_transfer_note_step.active).to be false
          expect(new_school_term_recovery_diary_record_step.active).to be false

          expect(new_conceptual_exam_step.id).not_to eq(conceptual_exam_step.id)
          expect(new_transfer_note_step.id).not_to eq(transfer_note_step.id)
          expect(new_school_term_recovery_diary_record_step.id).not_to eq(school_term_recovery_diary_record_step.id)
        end
      end

      it 'needs to create a new inactivate classroom_step and move descriptive_exams' do
        school_calendars['classrooms'].first['steps'].first['end_at'] = Date.new(Date.today.year, 8, 31)
        school_calendars['classrooms'].first['steps'].last['start_at'] = Date.new(Date.today.year, 9, 1)
        school_calendars['classrooms'].first['steps'].last['start_date_for_posting'] = Date.new(Date.today.year, 9, 1)

        updater = SchoolCalendarsUpdater.new(school_calendars)

        classroom_step = school_calendar_classroom.classroom_steps.last

        expect(descriptive_exam.school_calendar_classroom_step_id).to eq(classroom_step.id)
        expect(descriptive_exam.school_calendar_classroom_step.active).to be true

        updater.update!

        classroom_step = school_calendar_classroom.classroom_steps.first
        descriptive_exam.reload

        expect(descriptive_exam.school_calendar_classroom_step_id).not_to eq(classroom_step.id)
        expect(descriptive_exam.school_calendar_classroom_step.active).to be false
      end

      def school_calendars
        @school_calendars ||= begin
          school_calendars = school_calendar.serializable_hash(include: [:steps, :classrooms])
          school_calendars['school_calendar_id'] = school_calendars.delete('id')
          school_calendars['classrooms'].first['id'] = school_calendars['classrooms'].first.delete('classroom_id')
          school_calendars['classrooms'].first['steps'] = school_calendar.classrooms.first
                                                                         .serializable_hash(include: :classroom_steps)['classroom_steps']
          school_calendars['classrooms'].first['steps'].each { |item| item['_destroy'] = 'false' }
          school_calendars
        end
      end
    end
  end
end
