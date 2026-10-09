# Publica ("finaliza") uma versão do PEI: desativa a versão vigente, grava uma nova
# versão ativa com o snapshot completo do plano e marca o plano como finalizado (finalized_at).
class IndividualizedEducationalPlanPublisher
  def initialize(plan, name:, published_by:, student_data: nil, classroom: nil)
    @plan = plan
    @name = name
    @published_by = published_by
    @student_data = student_data
    @classroom = classroom
  end

  def self.publish!(plan, name:, published_by:, student_data: nil, classroom: nil)
    new(plan, name: name, published_by: published_by, student_data: student_data, classroom: classroom).publish!
  end

  def publish!
    plan.transaction do
      # Bulk desativa a versão ativa anterior — seguro: IepVersion não tem callbacks nem audited.
      plan.iep_versions.current.update_all(active: false)

      version = plan.iep_versions.create!(
        name: name,
        published_by: published_by,
        published_at: Time.current,
        active: true,
        classroom: classroom,
        content: IndividualizedEducationalPlanSnapshot.build(plan, student_data: student_data, classroom: classroom)
      )

      # O conteúdo atual passa a ser o da versão ativa; o próximo rascunho gravado zera de novo.
      plan.update_column(:finalized_at, version.published_at)

      version
    end
  end

  private

  attr_reader :plan, :name, :published_by, :student_data, :classroom
end
