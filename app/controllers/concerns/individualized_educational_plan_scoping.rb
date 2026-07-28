# Restringe o acesso aos PEIs às turmas do usuário (admin: turma do perfil; professor: as que
# leciona). Compartilhado entre os controllers de PEI e de versões: plano de turma sem vínculo →
# RecordNotFound. Fecha o IDOR tanto nas telas de leitura quanto no update (que busca por
# accessible_plans antes de gravar) e no destroy.
module IndividualizedEducationalPlanScoping
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :individualized_educational_plan_not_found
  end

  private

  def individualized_educational_plan_not_found
    redirect_to individualized_educational_plans_path,
                alert: I18n.t('individualized_educational_plans.flash.not_found')
  end

  def accessible_classrooms
    @accessible_classrooms ||=
      if current_user.current_role_is_admin_or_employee?
        [current_user_classroom].compact
      else
        fetched = TeacherClassroomAndDisciplineFetcher.fetch!(
          current_teacher.id, current_unity, current_school_year
        )
        # nil quando teacher/unity vêm em branco: o professor cai para [] e vê "PEI não
        # encontrado" num plano que pode ser dele — loga para tornar o caso diagnosticável.
        unless fetched
          Rails.logger.error(
            "PEI: TeacherClassroomAndDisciplineFetcher retornou nil — teacher=#{current_teacher&.id} " \
            "unity=#{current_unity&.id} year=#{current_school_year}"
          )
        end
        fetched ? fetched[:classrooms] : []
      end
  end

  def accessible_plans
    IndividualizedEducationalPlan.by_classroom_id(accessible_classrooms.map(&:id))
  end
end
