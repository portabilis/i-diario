# encoding: utf-8
class V1::AccessController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :configure_permitted_parameters
  skip_before_action :check_for_***REMOVED***

  def request_access

    verifier = RequestAccessVerifier.new(
      params[:IdAluno],
      params[:IdUnidade],
      params[:IdEquipamento]
    )

    if verifier.process!
      code = 1
      data = {
        "IdAluno" => params[:idAluno],
        "Mensagem" => "Acesso permitido",
        "Biometria" => verifier.biometric,
        "Senha" => nil,
        "Permissao" => 3
      }
    else
      code = 2
      data = {}
    end

    render json: {
      "Dados" => data,
      "Status" => {
        "Codigo" => code,
        "Mensagem" => verifier.response_msg
      }
    }
  end
end
