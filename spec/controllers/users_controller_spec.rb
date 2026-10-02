require 'rails_helper'

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

    describe "DELETE #destroy" do
      let(:deleted_user) { create(:user_with_user_role) }

      def destroy_params(search)
        { locale: 'pt-BR', id: deleted_user.id, search: search }
      end

      it "keeps the filled search filters in the redirect" do
        delete :destroy, params: destroy_params(by_name: 'Maria', status: '1')

        expect(response).to redirect_to(users_path(search: { by_name: 'Maria', status: '1' }))
      end

      it "drops the blank search filters from the redirect" do
        delete :destroy, params: destroy_params(by_name: 'Maria', by_cpf: '', email: '', login: '')

        expect(response).to redirect_to(users_path(search: { by_name: 'Maria' }))
      end

      it "redirects to the plain index when every filter is blank" do
        delete :destroy, params: destroy_params(by_name: '', by_cpf: '', email: '', login: '', status: '')

        expect(response).to redirect_to(users_path)
      end

      it "redirects to the plain index when search is not a hash" do
        delete :destroy, params: destroy_params('abc')

        expect(response).to redirect_to(users_path)
      end

      it "keeps the user and flashes the alert when it still has links" do
        create(:ieducar_api_synchronization, author: deleted_user)

        delete :destroy, params: destroy_params(by_name: 'Maria')

        expect(User.where(id: deleted_user.id)).to exist
        expect(flash[:alert]).to eq(
          I18n.t('flash.users.destroy.alert', resource_name: User.model_name.human)
        )
      end
    end
  end
end
