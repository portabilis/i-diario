# encoding: utf-8
class V1::AccessController < V1::BaseController

  def request_access

    verifier = RequestAccessVerifier.new(
      params[:IdAluno],
      params[:IdUnidade],
      params[:IdEquipamento],
      params[:Sentido].to_i,
      params[:DataHora],
      params[:TipoConsulta].to_i
    )

    if verifier.process!
      code = 1
      data = {
        "IdAluno" => params[:IdAluno],
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
    process_send_access params[:IdUnidade], params[:IdAluno], params[:DataHora], params[:IdEquipamento], params[:TipoAcesso].to_i
  end

  def send_access_batch
    process_send_access params[:IdUnidade], params[:IdAluno], params[:DataHora], params[:IdEquipamento], params[:Sentido].to_i
  end

  protected

  def process_send_access unity_code, student_code, datetime, equipment_code, access_type
    code = 1
    msg = "OK"

    if [1,2].include? access_type

      begin

        unity = Unity.find_by(api_code: unity_code)
        student = Student.find_by(api_code: student_code)

        access = ***REMOVED***.new(
          transaction_date: Time.parse(datetime),
          student: student,
          unity: unity,
          unity_equipment: UnityEquipment.find_by(code: equipment_code, unity_id: unity.try(:id)),
          operation: access_type == 1 ? "entrance" : "exit"
        )

        if !access.save
          code = 2
          msg = access.errors.full_messages.join(", ")
        end

      rescue ArgumentError
        code = 2
        msg = "Data e hora inválida"
      rescue
        code = 2
        msg = "Erro desconhecido"
      end
    elsif access_type != 3
      code = 2
      msg = "Sentido inválido"
    end

    render json: {
      "Codigo" => code,
      "Mensagem" => msg
    }

  end
end
