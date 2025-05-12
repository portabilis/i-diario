class AdjustSchoolTermTypeToTeachingPlans < ActiveRecord::Migration[4.2]
  def change
    TeachingPlan.where(school_term_type: nil).each do |teaching_plan|
      audited = teaching_plan.audits
                             .where(action: ['create', 'update'])
                             .where("audited_changes ILIKE '%school_term_type%' AND audited_changes ILIKE '%school_term%'")
                             .order(:version)
                             .last
      next if audited.blank?

      school_term = if audited.action == 'create'
                      audited.audited_changes['school_term']
                    else
                      audited.audited_changes['school_term'].last
                    end

      if school_term.ends_with?('bimester')
        steps_number = 4
        step_number = case school_term
                      when 'first_bimester' then 1
                      when 'second_bimester' then 2
                      when 'third_bimester' then 3
                      else 4
                      end
      elsif school_term.ends_with?('eja') || school_term.ends_with?('semester')
        steps_number = 2
        step_number = case school_term
                      when 'first_bimester_eja' then 1
                      when 'first_semester' then 1
                      when 'second_bimester_eja' then 2
                      else 2
                      end
      elsif school_term.ends_with?('trimester')
        steps_number = 3
        step_number = case school_term
                      when 'first_trimester' then 1
                      when 'second_trimester' then 2
                      else 3
                      end
      end

      if (school_term_type = SchoolTermType.find_by(steps_number: steps_number))

        school_term_type_step_id = SchoolTermTypeStep.find_by(
          school_term_type_id: school_term_type.id,
          step_number: step_number
        )&.id

        next if school_term_type_step_id.blank?

        teaching_plan.school_term_type_id = school_term_type.id
        teaching_plan.school_term_type_step_id = school_term_type_step_id
      else
        steps_types = SchoolTermType.where.not(description: 'Anual')
        current_step_type = steps_types.first
        current_steps_difference = (current_step_type.steps_number - steps_number).abs

        steps_types.each do |steps_type|
          tmp_steps_difference = (steps_type.steps_number - steps_number).abs

          if tmp_steps_difference < current_steps_difference
            current_steps_difference = tmp_steps_difference
            current_step_type = steps_type
          end
        end

        school_term_type_step = current_step_type.school_term_type_steps.find_by(step_number: step_number)

        next if school_term_type_step.blank?

        teaching_plan.school_term_type_id = current_step_type.id
        teaching_plan.school_term_type_step_id = school_term_type_step.id
      end

      teaching_plan.without_auditing do
        teaching_plan.save!(validate: false)
      end
    end
  end
end
