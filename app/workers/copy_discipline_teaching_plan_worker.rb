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
      model_discipline_teaching_plan = DisciplineTeachingPlan.find(discipline_teaching_plan_id)
      model_teaching_plan = model_discipline_teaching_plan.teaching_plan
      discipline_id = model_discipline_teaching_plan.discipline_id

      content_ids = []
      objective_ids = []

      teaching_plan_contents_created_at_position = {}
      teaching_plan_objectives_created_at_position = {}

      model_teaching_plan.contents_teaching_plans.each_with_index do |content_teaching_plan, index|
        teaching_plan_contents_created_at_position[content_teaching_plan.content_id] = index
        content_ids << content_teaching_plan.content_id
      end

      model_teaching_plan.objectives_teaching_plans.each do |objective_teaching_plan, index|
        teaching_plan_objectives_created_at_position[objective_teaching_plan.objective_id] = index
        objective_ids << objective_teaching_plan.objective_id
      end

      unities_ids.each do |unity_id|
        grades_ids.each do |grade_id|
          classrooms_in_grade = Classroom.by_unity(unity_id).by_grade(grade_id).pluck(:id)
          teacher_disciplines_classrooms = TeacherDisciplineClassroom.includes(:teacher).where(
            year: year,
            discipline_id: discipline_id,
            classroom_id: classrooms_in_grade
          )

          teacher_disciplines_classrooms.each do |teacher_discipline_classroom|
            teacher = teacher_discipline_classroom.teacher

            next unless teacher

            teaching_plan = model_teaching_plan.dup
            teaching_plan.unity_id = unity_id
            teaching_plan.grade_id = grade_id
            teaching_plan.contents_created_at_position = teaching_plan_contents_created_at_position
            teaching_plan.objectives_created_at_position = teaching_plan_objectives_created_at_position
            teaching_plan.content_ids = content_ids
            teaching_plan.objective_ids = objective_ids

            teaching_plan.build_discipline_teaching_plan(
              discipline_id: discipline_id,
              thematic_unit: model_discipline_teaching_plan.thematic_unit
            )

            teaching_plan.teacher = teacher
            teaching_plan.save!(validate: false)
          end
        end
      end

      SystemNotificationCreator.create!(
        source: model_discipline_teaching_plan,
        title: I18n.t('copy_discipline_teaching_plan_worker.title'),
        description: I18n.t('copy_discipline_teaching_plan_worker.description'),
        users: [User.find(user_id)]
      )
    end
  end
end
