module IndividualizedEducationalPlans
  class VersionsController < ApplicationController
    include IndividualizedEducationalPlanScoping

    before_action :require_current_teacher
    before_action :require_current_classroom
    # Controller aninhado: título/breadcrumb/menu usam o item do PEI no navigation.yml.
    before_action { @navigation_item = 'individualized_educational_plans' }

    def self._prefixes
      super + ['individualized_educational_plans']
    end

    def index
      @individualized_educational_plan = accessible_plans.find(
        params[:individualized_educational_plan_id]
      )
      authorize @individualized_educational_plan, :show?

      @versions = @individualized_educational_plan.iep_versions.includes(:published_by).recent_first
    end

    # Visualização de uma versão publicada: reconstrói o PEI congelado a partir do
    # snapshot (imutável) e renderiza a MESMA tela de formulário em modo leitura.
    def show
      iep = accessible_plans.find(params[:individualized_educational_plan_id])
      @version = iep.iep_versions.find(params[:id])

      authorize iep, :show?

      restored = IndividualizedEducationalPlanSnapshotRestorer.restore(@version.content)
      @individualized_educational_plan = restored.plan
      @students = restored.students
      @aee_teachers = restored.aee_teachers
      @iep_options_by_kind = restored.iep_options_by_kind
      @frozen_attachments = restored.attachments
      # Modal de adicionar componente não é renderizado no modo leitura (não precisa das listas).
      @disciplines = []
      @knowledge_areas = []
    rescue IndividualizedEducationalPlanSnapshotRestorer::InvalidSnapshot => e
      Honeybadger.notify(e, context: { version_id: @version&.id, iep_id: iep&.id })
      redirect_to individualized_educational_plan_versions_path(iep),
                  alert: t('individualized_educational_plans.versions.corrupted')
    end
  end
end
