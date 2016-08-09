class RequestAccessVerifier

  def initialize(student_api_code, unity_api_code, unity_equipment_code)
    @student_api_code = student_api_code
    @unity_api_code = unity_api_code
    @unity_equipment_code = unity_equipment_code
  end

  def process!
    student = Student.find_by(api_code: @student_api_code)
    if student.blank?
      self.response_msg = "Aluno inválido"
      valid = false
      return true
    end

    unity = Unity.find_by(api_code: @unity_api_code)
    if unity.blank?
      self.response_msg = "Escola inválida"
      valid = false
      return true
    end

    unity_equipment = unity.unity_equipments.find_by(code: @unity_equipment_code)
    if unity_equipment.blank?
      self.response_msg = "Equipamento inválido"
      valid = false
      return true
    end

    student_biometric = student.student_biometrics.where(biometric_type: unity_equipment.biometric_type)
    if student_biometric.blank?
      self.response_msg = "Biometria não cadastrada"
      valid = false
      return true
    end

    if !StudentUnityChecker.new(student, unity).present?
      self.response_msg = "Acesso negado"
      valid = false
      return true
    end

    biometric = student_biometric.biometric
    self.response_msg = "OK"
    valid = true
  end

  attr_reader :response_msg, :valid, :biometric

  private

  attr_writer :response_msg, :valid, :biometric
end
