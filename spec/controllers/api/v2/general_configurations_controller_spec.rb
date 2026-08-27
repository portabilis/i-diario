require 'rails_helper'

RSpec.describe Api::V2::GeneralConfigurationsController, type: :controller do
  include_context 'api v2 ieducar token'

  describe 'GET #show' do
    it 'returns 401 without a valid token' do
      request.headers['token'] = 'invalid'

      get :show, params: { format: :json, locale: 'en' }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'exposes the absence thresholds configured by the city' do
      GeneralConfiguration.current.update!(
        notify_consecutive_or_alternate_absences: true,
        max_consecutive_absence_days: 4,
        max_alternate_absence_days: 6,
        days_to_consider_alternate_absences: 10
      )

      get :show, params: { format: :json, locale: 'en' }

      expect(response).to have_http_status(:success)

      body = JSON.parse(response.body)

      expect(body).to eq(
        'notify_consecutive_or_alternate_absences' => true,
        'max_consecutive_absence_days' => 4,
        'max_alternate_absence_days' => 6,
        'days_to_consider_alternate_absences' => 10
      )
    end

    # Os três campos só são exigidos quando o aviso está ligado: rede que não
    # usa a régua devolve nulo, e quem lê precisa saber disso em vez de receber
    # um padrão inventado.
    it 'returns null thresholds when the notification is off' do
      GeneralConfiguration.current.update!(
        notify_consecutive_or_alternate_absences: false,
        max_consecutive_absence_days: nil,
        max_alternate_absence_days: nil,
        days_to_consider_alternate_absences: nil
      )

      get :show, params: { format: :json, locale: 'en' }

      body = JSON.parse(response.body)

      expect(body).to eq(
        'notify_consecutive_or_alternate_absences' => false,
        'max_consecutive_absence_days' => nil,
        'max_alternate_absence_days' => nil,
        'days_to_consider_alternate_absences' => nil
      )
    end
  end
end
