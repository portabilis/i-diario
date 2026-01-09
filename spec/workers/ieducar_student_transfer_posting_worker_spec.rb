# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IeducarStudentTransferPostingWorker, type: :worker do
  let(:entity) { Entity.find_by_domain('test.host') }
  let!(:ieducar_api_configuration) { create(:ieducar_api_configuration) }
  let!(:unity) { create(:unity) }
  let!(:classroom) do
    create(
      :classroom,
      :with_classroom_semester_steps,
      :score_type_numeric_and_concept_create_rule,
      unity: unity
    )
  end
  let!(:student_enrollment_classroom) do
    create(
      :student_enrollment_classroom,
      classrooms_grade: classroom.classrooms_grades.first,
      joined_at: classroom.calendar.classroom_steps.first.start_at
    )
  end
  let(:student) { student_enrollment_classroom.student_enrollment.student }
  let(:callback_url) { 'https://ieducar.example.com/api/transfer/callback' }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  describe '#perform' do
    let(:fetcher_double) { instance_double(IeducarStudentTransferDataFetcher) }

    before do
      allow(IeducarStudentTransferDataFetcher).to receive(:new).and_return(fetcher_double)
      allow(fetcher_double).to receive(:post_to_ieducar!)
    end

    it 'calls the data fetcher with correct student and classroom' do
      stub_request(:post, callback_url).to_return(status: 200)

      expect(IeducarStudentTransferDataFetcher).to receive(:new).with(
        student: student,
        classroom: classroom
      ).and_return(fetcher_double)
      expect(fetcher_double).to receive(:post_to_ieducar!)

      described_class.new.perform(entity.id, student.id, classroom.id, callback_url)
    end

    context 'when processing succeeds' do
      it 'sends success webhook with correct payload' do
        webhook_stub = stub_request(:post, callback_url).to_return(status: 200)

        described_class.new.perform(entity.id, student.id, classroom.id, callback_url)

        expect(webhook_stub).to have_been_requested.once
        expect(WebMock).to have_requested(:post, callback_url).with { |req|
          body = JSON.parse(req.body)
          body['status'] == 'success' &&
            body['student_id'] == student.api_code &&
            body['classroom_id'] == classroom.api_code &&
            !body.key?('error')
        }
      end
    end

    context 'when processing fails' do
      before do
        allow(fetcher_double).to receive(:post_to_ieducar!).and_raise(StandardError, 'Test error')
      end

      it 'sends error webhook and re-raises exception' do
        webhook_stub = stub_request(:post, callback_url).to_return(status: 200)

        expect do
          described_class.new.perform(entity.id, student.id, classroom.id, callback_url)
        end.to raise_error(StandardError, 'Test error')

        expect(webhook_stub).to have_been_requested.once
        expect(WebMock).to have_requested(:post, callback_url).with { |req|
          body = JSON.parse(req.body)
          body['status'] == 'error' &&
            body['student_id'] == student.api_code &&
            body['classroom_id'] == classroom.api_code &&
            body['error'] == 'Test error'
        }
      end
    end

    context 'when webhook delivery fails' do
      before do
        stub_request(:post, callback_url).to_return(status: 500)
      end

      it 'logs error but does not raise exception' do
        expect(Rails.logger).to receive(:error).with(
          /IeducarStudentTransferPostingWorker: Failed to send confirmation webhook/
        )

        expect do
          described_class.new.perform(entity.id, student.id, classroom.id, callback_url)
        end.not_to raise_error
      end

      it 'still processes data even if webhook fails' do
        expect(fetcher_double).to receive(:post_to_ieducar!)

        described_class.new.perform(entity.id, student.id, classroom.id, callback_url)
      end
    end
  end

  describe 'Sidekiq options' do
    it 'uses critical queue' do
      expect(described_class.sidekiq_options['queue']).to eq(:critical)
    end

    it 'has retry set to 3' do
      expect(described_class.sidekiq_options['retry']).to eq(3)
    end
  end
end
