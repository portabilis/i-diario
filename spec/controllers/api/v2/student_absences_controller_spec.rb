require 'rails_helper'

RSpec.describe Api::V2::StudentAbsencesController, type: :controller do
  include_context 'api v2 ieducar token'

  describe 'GET #index' do
    it_behaves_like 'an api v2 unity period endpoint', Api::StudentAbsencesService
  end
end
