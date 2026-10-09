# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::IeducarApiStudentTransfersController, type: :controller do
  describe 'POST #create' do
    let(:entity) { Entity.find_by_domain('test.host') }
    let(:ieducar_api_configuration) { create(:ieducar_api_configuration) }
    let(:student_enrollment_classroom) { create(:student_enrollment_classroom) }
    let(:student_enrollment) do
      enrollment = student_enrollment_classroom.student_enrollment
      enrollment.update!(api_code: '12345') unless enrollment.api_code.present?
      enrollment
    end
    let(:student) { student_enrollment.student }
    let(:classroom) { student_enrollment_classroom.classrooms_grade.classroom }
    let(:callback_url) { 'https://ieducar.example.com/api/transfer/callback' }

    around(:each) do |example|
      entity.using_connection do
        example.run
      end
    end

    before do
      request.env['REQUEST_PATH'] = '/api/v2/ieducar_api_student_transfers'
      request.headers['token'] = ieducar_api_configuration.api_security_token
    end

    context 'with valid params' do
      it 'returns 202 accepted and enqueues the worker' do
        params = {
          student_enrollment_api_code: student_enrollment.api_code,
          callback_url: callback_url,
          format: 'json',
          locale: 'en'
        }

        expect(IeducarStudentTransferPostingWorker).to receive(:perform_async).with(
          entity.id,
          student.id,
          classroom.id,
          callback_url,
          nil
        )

        post :create, params: params, xhr: true

        expect(response).to have_http_status(:accepted)

        json = ActiveSupport::JSON.decode(response.body)
        expect(json['status']).to eq('processing')
      end

      it 'forwards the transfer_date to the worker when provided' do
        transfer_date = '2026-07-14'
        params = {
          student_enrollment_api_code: student_enrollment.api_code,
          callback_url: callback_url,
          transfer_date: transfer_date,
          format: 'json',
          locale: 'en'
        }

        expect(IeducarStudentTransferPostingWorker).to receive(:perform_async).with(
          entity.id,
          student.id,
          classroom.id,
          callback_url,
          transfer_date
        )

        post :create, params: params, xhr: true

        expect(response).to have_http_status(:accepted)
      end
    end

    context 'with invalid transfer_date' do
      it 'returns 400 bad request and does not enqueue the worker' do
        params = {
          student_enrollment_api_code: student_enrollment.api_code,
          callback_url: callback_url,
          transfer_date: 'not-a-date',
          format: 'json',
          locale: 'en'
        }

        expect(IeducarStudentTransferPostingWorker).not_to receive(:perform_async)

        post :create, params: params, xhr: true

        expect(response).to have_http_status(:bad_request)

        json = ActiveSupport::JSON.decode(response.body)
        expect(json['error']).to include('transfer_date')
      end
    end

    context 'with missing params' do
      it 'returns 400 bad request when student_enrollment_api_code is missing' do
        params = {
          callback_url: callback_url,
          format: 'json',
          locale: 'en'
        }

        post :create, params: params, xhr: true

        expect(response).to have_http_status(:bad_request)

        json = ActiveSupport::JSON.decode(response.body)
        expect(json['error']).to include('student_enrollment_api_code')
      end

      it 'returns 400 bad request when callback_url is missing' do
        params = {
          student_enrollment_api_code: student_enrollment.api_code,
          format: 'json',
          locale: 'en'
        }

        post :create, params: params, xhr: true

        expect(response).to have_http_status(:bad_request)

        json = ActiveSupport::JSON.decode(response.body)
        expect(json['error']).to include('callback_url')
      end
    end

    context 'with invalid student enrollment' do
      it 'returns 404 when student enrollment is not found' do
        params = {
          student_enrollment_api_code: '999999',
          callback_url: callback_url,
          format: 'json',
          locale: 'en'
        }

        post :create, params: params, xhr: true

        expect(response).to have_http_status(:not_found)

        json = ActiveSupport::JSON.decode(response.body)
        expect(json['error']).to eq('Matrícula não encontrada')
      end
    end

    context 'with invalid token' do
      before do
        request.headers['token'] = 'invalid_token'
      end

      it 'returns 401 unauthorized' do
        params = {
          student_enrollment_api_code: student_enrollment.api_code,
          callback_url: callback_url,
          format: 'json',
          locale: 'en'
        }

        post :create, params: params, xhr: true

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
