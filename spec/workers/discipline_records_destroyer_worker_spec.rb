# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DisciplineRecordsDestroyerWorker, type: :worker do
  let(:year) { Date.current.year }
  let(:unity) { create(:unity) }
  let(:course) { create(:course) }
  let(:grade) { create(:grade, course: course) }
  let(:discipline) { create(:discipline) }
  let(:classroom) do
    create(:classroom, :with_classroom_semester_steps, unity: unity, year: year)
  end
  let!(:classrooms_grade) do
    create(:classrooms_grade, classroom: classroom, grade: grade)
  end
  let(:entity) { Entity.find_by_domain('test.host') }
  let(:operation_id) { 42 }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  before do
    IeducarApiConfiguration.current.update!(
      url: 'http://test.ieducar.com.br',
      token: '8IOwGIjiHvbeTklgwo10yVLgwDhhvs',
      secret_token: '5y8cfq31oGvFdAlGMCLIeSKdfc8pUC',
      unity_code: 1,
      api_security_token: 'test_token'
    )
  end

  describe '#perform' do
    it 'destroys records and marks deletion as completed' do
      create(
        :daily_frequency,
        classroom: classroom,
        discipline: discipline,
        unity: unity,
        frequency_date: Date.current,
        school_calendar: classroom.calendar.school_calendar
      )

      deletion = DisciplineRecordDeletion.create!(
        filters: {
          year: year,
          unities_api_code: [unity.api_code.to_s],
          courses_api_code: [course.api_code.to_s],
          grades_api_code: [grade.api_code.to_s],
          disciplines_api_code: [discipline.api_code.to_s],
          user_api_code: '1'
        },
        status: DisciplineRecordDeletionStatus::PROCESSING
      )

      expect {
        subject.perform(entity.id, deletion.id)
      }.to change(DailyFrequency, :count).by(-1)

      deletion.reload
      expect(deletion.status).to eq(DisciplineRecordDeletionStatus::COMPLETED)
      expect(deletion.total_deleted).to eq(1)
      expect(deletion.error_message).to be_nil
    end

    it 'marks deletion as error on failure' do
      deletion = DisciplineRecordDeletion.create!(
        filters: {
          year: year,
          unities_api_code: [unity.api_code.to_s],
          courses_api_code: [course.api_code.to_s],
          grades_api_code: [grade.api_code.to_s],
          disciplines_api_code: [discipline.api_code.to_s],
          user_api_code: '1'
        },
        status: DisciplineRecordDeletionStatus::PROCESSING
      )

      allow(Api::DisciplineRecordsDestroyer).to receive(:new).and_raise(StandardError, 'test error')

      subject.perform(entity.id, deletion.id)

      deletion.reload
      expect(deletion.status).to eq(DisciplineRecordDeletionStatus::ERROR)
      expect(deletion.error_message).to eq('test error')
    end

    it 'sends callback on success' do
      deletion = DisciplineRecordDeletion.create!(
        filters: {
          year: year,
          unities_api_code: [unity.api_code.to_s],
          courses_api_code: [course.api_code.to_s],
          grades_api_code: [grade.api_code.to_s],
          disciplines_api_code: [discipline.api_code.to_s],
          user_api_code: '1'
        },
        status: DisciplineRecordDeletionStatus::PROCESSING,
        operation_id: operation_id
      )

      api_instance = instance_double(IeducarApi::PostComponentBatchCallback)
      allow(IeducarApi::PostComponentBatchCallback).to receive(:new).and_return(api_instance)

      expect(api_instance).to receive(:send_post).with(
        hash_including(success: true, deleted: 0, operation_id: operation_id)
      )

      subject.perform(entity.id, deletion.id)
    end

    it 'sends callback on error' do
      deletion = DisciplineRecordDeletion.create!(
        filters: {
          year: year,
          unities_api_code: [unity.api_code.to_s],
          courses_api_code: [course.api_code.to_s],
          grades_api_code: [grade.api_code.to_s],
          disciplines_api_code: [discipline.api_code.to_s],
          user_api_code: '1'
        },
        status: DisciplineRecordDeletionStatus::PROCESSING,
        operation_id: operation_id
      )

      allow(Api::DisciplineRecordsDestroyer).to receive(:new).and_raise(StandardError, 'test error')

      api_instance = instance_double(IeducarApi::PostComponentBatchCallback)
      allow(IeducarApi::PostComponentBatchCallback).to receive(:new).and_return(api_instance)

      expect(api_instance).to receive(:send_post).with(
        hash_including(success: false, error: 'test error', operation_id: operation_id)
      )

      subject.perform(entity.id, deletion.id)
    end

    it 'does not send callback when operation_id is blank' do
      deletion = DisciplineRecordDeletion.create!(
        filters: {
          year: year,
          unities_api_code: [unity.api_code.to_s],
          courses_api_code: [course.api_code.to_s],
          grades_api_code: [grade.api_code.to_s],
          disciplines_api_code: [discipline.api_code.to_s],
          user_api_code: '1'
        },
        status: DisciplineRecordDeletionStatus::PROCESSING
      )

      expect(IeducarApi::PostComponentBatchCallback).not_to receive(:new)

      subject.perform(entity.id, deletion.id)

      deletion.reload
      expect(deletion.status).to eq(DisciplineRecordDeletionStatus::COMPLETED)
    end

    it 'does not fail when callback request fails' do
      deletion = DisciplineRecordDeletion.create!(
        filters: {
          year: year,
          unities_api_code: [unity.api_code.to_s],
          courses_api_code: [course.api_code.to_s],
          grades_api_code: [grade.api_code.to_s],
          disciplines_api_code: [discipline.api_code.to_s],
          user_api_code: '1'
        },
        status: DisciplineRecordDeletionStatus::PROCESSING,
        operation_id: operation_id
      )

      api_instance = instance_double(IeducarApi::PostComponentBatchCallback)
      allow(IeducarApi::PostComponentBatchCallback).to receive(:new).and_return(api_instance)
      allow(api_instance).to receive(:send_post).and_raise(StandardError, 'connection refused')

      subject.perform(entity.id, deletion.id)

      deletion.reload
      expect(deletion.status).to eq(DisciplineRecordDeletionStatus::COMPLETED)
    end
  end
end
