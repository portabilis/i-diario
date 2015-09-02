module Turnip
  module CurrentUserRoleSteps
    step 'que possuo múltiplos perfis' do
      user = users(:john_doe)
      @user_role = create(:user_role, user: user)
      user.user_roles << @user_role
      user.save
    end

    step 'eu alterar o meu perfil atual' do
      expect(page).to_not have_content(@user_role.to_s)

      find('header#header div#change-permission a.dropdown-toggle').click

      click_link @user_role.to_s
    end

    step 'irei visualizar uma mensagem de perfil atual alterado com sucesso' do
      expect(page).to have_content('Dashboard')
      expect(page).to have_content('Perfil alterado com sucesso')
    end

    step 'estarei logado com outro perfil' do
      expect(page).to have_content(@user_role.to_s)
    end
  end
end

RSpec.configure do |config|
  config.include Turnip::CurrentUserRoleSteps
end
