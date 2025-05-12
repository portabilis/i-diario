require 'spec_helper'

RSpec.describe UsersController, :type => :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:user) { create(:user_with_user_role) }
  let(:unity) { create(:unity) }
  let(:user_role) { user.user_roles.first }

  before do
    user_role.unity = unity
    user_role.save!

    user.current_user_role = user_role
    user.save!

    sign_in(user)
    allow(controller).to receive(:authorize).and_return(true)
    request.env['REQUEST_PATH'] = ''
  end

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  context "pt-BR routes" do
    it "routes to index" do
      expect(get: "usuarios").to route_to(
        controller: "users",
        action: "index",
        locale: "pt-BR"
      )
    end

    it "routes to edit" do
      expect(get: "usuarios/1/editar").to route_to(
        action: "edit",
        controller: "users",
        locale: "pt-BR",
        id: "1"
      )
    end

    it "routes to update" do
      expect(put: "usuarios/1").to route_to(
        action: "update",
        controller: "users",
        locale: "pt-BR",
        id: "1"
      )
    end

    describe "GET #index" do
      let(:params) do
        {
          locale: 'pt-BR',
          search: {
            by_name: user.name
          }
        }
      end

      it "with correct params" do
        get :index, params: params
        expect(response).to have_http_status(:ok)
      end

      it "without correct params" do
        get :index, params: params.merge(search: { wrong_name: nil })
        expect(response).to have_http_status(302)
      end
    end

    describe "PUT #update" do
      it "with correct params and a weak password" do

        params = {
          locale: 'pt-BR',
          id: user.id,
          user: {
            password: '123456',
            admin: '0',
            user_roles_attributes: {
              '0' => {
                id: user_role.id,
                role_id: user_role.role_id,
                unity_id: unity.id,
                _destroy: false
              }
            }
          }
        }

        put :update, params: params

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:edit)
      end

      it "with correct params and a strong password" do
        new_params = {
          locale: 'pt-BR',
          id: user.id,
          user: {
            password: '!Aa123456',
            admin: '0',
            user_roles_attributes: {
              '0' => {
                id: user_role.id,
                role_id: user_role.role_id,
                unity_id: unity.id,
                _destroy: false
              }
            }
          }
        }

        put :update, params: new_params
        expect(response).to redirect_to(users_path)
      end
    end
  end
end
