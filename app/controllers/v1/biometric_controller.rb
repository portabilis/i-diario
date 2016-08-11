# encoding: utf-8
class V1::BiometricController < V1::BaseController

  def send_biometric
    student_api_code = params[:IdAluno]
    biometric = params[:Biometria]
    biometric_type = params[:TipoBiometria]

    student_biometric = StudentBiometric.find_or_initialize_by(
      student: Student.find_by(api_code: student_api_code),
      biometric_type: biometric_type
    )
    student_biometric.biometric = biometric

    if student_biometric.save
      code = 1
      msg = "OK"
    else
      code = 2
      msg = student_biometric.errors.full_messages.join(", ")
    end

    render json: {
      "Codigo" => code,
      "Mensagem" => msg
    }
  end
end
