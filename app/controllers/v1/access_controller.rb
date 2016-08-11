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

  def send_access
    code = 1
    msg = "OK"
    if params[:TipoAcesso] != 3
      unity = Unity.find_by(api_code: params[:IdUnidade])
      student = Student.find_by(api_code: params[:IdAluno])

      access = ***REMOVED***.new(
        transaction_date: Time.parse(params[:DataHora]),
        student: student,
        unity: unity,
        unity_equipment: UnityEquipment.find_by(code: params[:IdEquipamento], unity_id: unity.id),
        operation: params[:TipoAcesso] == 1 ? "entrance" : "exit"
      )

      if !access.save
        code = 2
        msg = access.errors.full_messages.join(", ")
      end
    end

    render json: {
      "Codigo" => code,
      "Mensagem" => msg
    }
  end
end
