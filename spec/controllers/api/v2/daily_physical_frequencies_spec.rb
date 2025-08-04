require 'rails_helper'

RSpec.describe Api::V2::DailyPhysicalFrequenciesController, type: :controller do

  around(:each) do |example|
    Entity.find_by_domain("test.host").using_connection do
      example.run
    end
  end

  describe "POST #create" do
    let!(:unity) { create(:unity, api_code: "1") }
    let!(:enrollment1) { create(:student_enrollment, api_code: "1") }
    let!(:enrollment2) { create(:student_enrollment, api_code: "2") }
    let(:json_response) { JSON.parse(response.body) }

    before do
      allow(controller).to receive(:authenticate_api!)
    end

    context "with a valid payload and all new records" do
      let(:valid_payload) do
        [
          { unity_api_code: "1", student_enrollment_api_code: "1", frequency_date: "2025-07-30", present: true },
          { unity_api_code: "1", student_enrollment_api_code: "2", frequency_date: "2025-07-30", present: false }
        ]
      end

      before do
        allow_any_instance_of(DailyPhysicalFrequency).to receive(:valid?).and_return(true)
      end

      it "creates the frequency records in the database" do
        expect {
          post :create, params: { _json: valid_payload, format: "json", locale: "en" }, xhr: true
        }.to change(DailyPhysicalFrequency, :count).by(2)
      end

      it "returns 201 Created and the correct count" do
        post :create, params: { _json: valid_payload, locale: "en" }, xhr: true
        expect(response).to have_http_status(:created)
        expect(json_response["created_count"]).to eq(2)
      end
    end

    context "with invalid data" do
      it "returns 422 error if a unity is not found" do
        payload = [{ unity_api_code: "NON-EXISTENT", student_enrollment_api_code: "1", frequency_date: "2025-07-30", present: true }]
        post :create, params: { _json: payload, locale: "en" }, xhr: true
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"].first["error"]).to include("Unidade com api_code 'NON-EXISTENT' não encontrada.")
      end

      it "returns 422 error if a student enrollment is not found" do
        payload = [{ unity_api_code: "1", student_enrollment_api_code: "NON-EXISTENT", frequency_date: "2025-07-30", present: true }]
        post :create, params: { _json: payload, locale: "en" }, xhr: true
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"].first["error"]).to include("Matrícula com api_code 'NON-EXISTENT' não encontrada.")
      end

      it "returns 422 error if a field fails model validation" do
        payload = [{ unity_api_code: "1", student_enrollment_api_code: "1", frequency_date: "2025-07-30", present: nil }]
        post :create, params: { _json: payload, locale: "en" }, xhr: true
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["errors"].first["error"].first).to include("Present não está incluído na lista")
      end

      it "does not create any record if one item in the batch is invalid (atomicity)" do
        invalid_payload = [
          { unity_api_code: "1", student_enrollment_api_code: "1", frequency_date: "2025-07-30", present: true }, # Válido
          { unity_api_code: "NON-EXISTENT", student_enrollment_api_code: "2", frequency_date: "2025-07-30", present: true } # Inválido
        ]
        expect {
          post :create, params: { _json: invalid_payload, locale: "en" }, xhr: true
        }.not_to change(DailyPhysicalFrequency, :count)
      end
    end

    context "with malformed payload" do
      it "returns 400 error if payload is not an array" do
        request.headers['Accept'] = 'application/json'
        post :create, params: { not_an: "array", locale: "en" }, xhr: true
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "without authentication" do
      before do
        allow(controller).to receive(:authenticate_api!).and_call_original
      end

      it "returns 401 Unauthorized error" do
        post :create, params: { _json: [], locale: "en" }, xhr: true
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
