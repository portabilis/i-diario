# Publica ("finaliza") uma versão do PEI: desativa a versão vigente, grava uma nova
# versão ativa com o snapshot completo do plano e atualiza o cache finalized_at.
class IndividualizedEducationalPlanPublisher
  def initialize(plan, name, published_by)
    @plan = plan
    @name = name
    @published_by = published_by
  end

  def self.publish!(plan, name:, published_by:)
    new(plan, name, published_by).publish!
  end

  def publish!
    plan.transaction do
      plan.iep_versions.current.update_all(active: false)

      version = plan.iep_versions.create!(
        name: name,
        published_by: published_by,
        published_at: Time.current,
        active: true,
        content: IndividualizedEducationalPlanSnapshot.build(plan)
      )

      # Cache do estado "finalizado" (a verdade é a existência de versão ativa).
      plan.update_column(:finalized_at, version.published_at)

      version
    end
  end

  private

  attr_reader :plan, :name, :published_by
end
