# encoding: utf-8
class CurrentRoleController < ApplicationController
  def index
    @user_roles = current_user.user_roles
  end

  def set
    if current_user.set_role!(params[:id])
      redirect_to root_path, notice: "Perfil alterado com sucesso."
    else
      redirect_to root_path, alert: "Perfil não pode ser alterado. Verifique se o usuário possui este perfil."
    end
  end
end
