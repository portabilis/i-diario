# Restringe o acesso aos PEIs às turmas do usuário, derivando do GRAFO DE MATRÍCULA (o PEI
# segue o aluno por transferências de turma/escola). Compartilhado entre os controllers de PEI
# e de versões: plano de aluno sem vínculo com as turmas do usuário → RecordNotFound.
#
# - Visibilidade (accessible_plans): o PEI aparece na turma do usuário se o aluno está CURSANDO ela
#   agora (continuidade) OU se aquela turma JÁ PUBLICOU alguma versão (autoria — iep_versions.classroom_id).
#   A autoria é gravada no publish, então "quem lançou vê o que lançou" mesmo com transferência de data
#   retroativa; e uma turma por onde o aluno só passou (sem lançar nada) não vê o plano.
# - Edição (plan_editable?): só com enturmação ABERTA numa turma do usuário (aluno cursando).
#   Turma autora onde aluno não cursa mais → leitura da versão congelada na sua última contribuição.
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

  def accessible_classroom_ids
    @accessible_classroom_ids ||= accessible_classrooms.map(&:id)
  end

  # Planos que o usuário enxerga, do ANO LETIVO CORRENTE: aluno cursando uma turma dele, OU turma
  # dele que já publicou alguma versão do plano (autoria).
  def accessible_plans
    IndividualizedEducationalPlan.kept
                                 .where(year: current_school_year)
                                 .by_classroom_id(accessible_classroom_ids)
  end

  # Editável quando o aluno está CURSANDO uma turma do usuário (matrícula em status de
  # frequência + enturmação aberta — ver attending_on). Transferido/abandono/reclassificado/
  # enturmação fechada → somente leitura.
  def plan_editable?(plan)
    cache = (@plan_editable_cache ||= {})
    return cache[plan.id] if cache.key?(plan.id)

    cache[plan.id] = StudentEnrollmentClassroom.attending_any_classroom?(
      accessible_classroom_ids, plan.student_id
    )
  end

  # Congelamento por autoria: quem não cursa mais o aluno vê o PEI só até a última versão que uma
  # turma sua publicou (nil = cursando, vê o vivo). Memoizado com key? porque o resultado pode ser nil.
  def freeze_date_for(plan)
    cache = (@freeze_date_for ||= {})
    return cache[plan.id] if cache.key?(plan.id)

    cache[plan.id] =
      if plan_editable?(plan)
        nil
      else
        plan.iep_versions.by_classroom(accessible_classroom_ids).maximum(:published_at)
      end
  end

  # Versão que o autor inativo enxerga na tela: a mais recente publicada até a sua última contribuição.
  def frozen_version_for(plan)
    date = freeze_date_for(plan)
    return unless date

    plan.iep_versions.where('published_at <= ?', date).recent_first.first
  end

  # Versões visíveis no histórico: para o autor inativo, só até a sua última contribuição.
  def versions_for(plan)
    versions = plan.iep_versions.includes(:published_by).recent_first
    date = freeze_date_for(plan)
    date ? versions.where('published_at <= ?', date) : versions
  end

  # Versão publicada DEPOIS da última contribuição do usuário: escondida pelo congelamento.
  def version_frozen_out?(plan, version)
    date = freeze_date_for(plan)
    date.present? && version.published_at > date
  end
end
