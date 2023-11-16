class CopyDisciplineTeachingPlanWorker
  include Sidekiq::Worker

  def perform(
    entity_id,
    user_id,
    discipline_teaching_plan_id,
    year,
    unities_ids,
    grades_ids
  )
    Entity.find(entity_id).using_connection do
      CopyDisciplineTeachingPlanService.call(
        entity_id,
        user_id,
        discipline_teaching_plan_id,
        year,
        unities_ids,
        grades_ids
      )

      SystemNotificationCreator.create!(
        source: model_discipline_teaching_plan,
        title: I18n.t('copy_discipline_teaching_plan_worker.title'),
        description: I18n.t('copy_discipline_teaching_plan_worker.description'),
        users: [User.find(user_id)]
      )
    end
  end
end
