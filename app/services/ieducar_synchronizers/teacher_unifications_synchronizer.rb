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
    main_ids = unifications.map(&:main_id).compact
    duplicate_ids = unifications.flat_map { |unification| convert_struct_to_array(unification) }.compact

    preload_teachers(main_ids + duplicate_ids)

    errors = []

    unifications.each do |unification|
      next if unification.main_id.blank?

      teacher = teacher(unification.main_id)

      next if teacher.blank?

      begin
        ActiveRecord::Base.transaction { update_teacher_unification(teacher, unification) }
      rescue StandardError => error
        # Uma unificação com erro não impede as demais; o erro é relançado no fim para
        # marcar a sincronização, e a próxima tenta de novo porque nada foi gravado.
        Rails.logger.error(
          "[TeacherUnificationsSynchronizer] falha ao unificar o professor #{unification.main_id} " \
          "(entity_id: #{entity_id}): #{error.class}: #{error.message}"
        )
        errors << error
      end
    end

    raise errors.first if errors.any?
  end

  def update_teacher_unification(teacher, unification)
    teacher_unification = TeacherUnification.find_or_initialize_by(teacher_id: teacher.id)
    teacher_unification.unified_at = unification.created_at
    teacher_unification.active = unification.active

    secondary_teachers = convert_struct_to_array(unification).map { |api_code| teacher(api_code) }.compact

    if teacher_unification.changed?
      save_teacher_unification(
        teacher_unification: teacher_unification,
        unification: unification,
        main_teacher: teacher,
        secondary_teachers: secondary_teachers
      )
    elsif pending_unification?(unification, secondary_teachers)
      TeacherUnification::UnificationService.new(teacher, secondary_teachers).run!
    end
  end

  def save_teacher_unification(teacher_unification:, unification:, main_teacher:, secondary_teachers:)
    new_record = teacher_unification.new_record?

    teacher_unification.save!

    if new_record
      secondary_teachers.each do |secondary_teacher|
        teacher_unification.unified_teachers.create!(teacher: secondary_teacher)
      end
    end

    return if !unification.active && new_record

    unify_or_revert(unification.active, main_teacher, secondary_teachers)
  end

  # Unificação ativa com professor secundário ainda não descartado ficou pela metade.
  def pending_unification?(unification, secondary_teachers)
    teacher_unification.active && secondary_teachers.any?(&:kept?)
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
