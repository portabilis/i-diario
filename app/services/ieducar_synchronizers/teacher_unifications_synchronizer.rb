class TeacherUnificationsSynchronizer < BaseSynchronizer
  def synchronize!
    update_teacher_unifications(
      HashDecorator.new(
        api.fetch(ignore_modified: true)['unificacoes']
      )
    )
  rescue IeducarApi::Base::ApiError => error
    synchronization.mark_as_error!(error.message)
  end

  private

  def api_class
    IeducarApi::TeacherUnifications
  end

  def update_teacher_unifications(unifications)
    unifications.each do |unification|
      next if unification.main_id.blank?

      teacher = teacher(unification.main_id)

      next if teacher.blank?

      update_teacher_unification(teacher, unification)
    end
  end

  def update_teacher_unification(teacher, unification)
    TeacherUnification.find_or_initialize_by(
      teacher_id: teacher.id
    ).tap do |teacher_unification|
      teacher_unification.unified_at = unification.created_at
      teacher_unification.active = unification.active

      if teacher_unification.changed?
        new_record = teacher_unification.new_record?

        teacher_unification.save!

        duplicates_ids = convert_struct_to_array(unification)

        secondary_teachers = duplicates_ids.map { |api_code|
          teacher(api_code)
        }.compact

        if new_record
          secondary_teachers.each do |secondary_teacher|
            teacher_unification.unified_teachers.create!(
              teacher: secondary_teacher
            )
          end
        end
        next if !unification.active && new_record

        unify_or_revert(unification.active, teacher, secondary_teachers)
      end
    end
  end

  def convert_struct_to_array(unification)
    unification.duplicates_id.kind_of?(Array) ? unification.duplicates_id : unification.duplicates_id.to_h.values
  end

  def unify_or_revert(unify, main_teacher, secondary_teachers)
    if unify
      TeacherUnification::UnificationService.new(main_teacher, secondary_teachers).run!
    else
      TeacherUnification::ReverterService.new(main_teacher, secondary_teachers).run!
    end
  end
end
