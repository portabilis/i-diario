class ClassroomsSynchronizer < BaseSynchronizer
  def synchronize!
    update_classrooms(
      HashDecorator.new(
        api.fetch(
          escola: unity_api_code,
          ano: year
        )['turmas']
      )
    )
  end

  private

  def api_class
    IeducarApi::Classrooms
  end

  def update_classrooms(classrooms)
    @modified_at = api.send(:get_modified_date) unless synchronization.full_synchronization?

    all_grades = classrooms.flat_map(&:series_regras)

    preload_unities(classrooms.map(&:escola_id))
    preload_classrooms(classrooms.map(&:id))
    preload_grades(all_grades.map(&:serie_id).compact)
    preload_exam_rules(all_grades.map(&:regra_avaliacao_id).compact)

    classrooms.each do |classroom_record|
      unity = unity(classroom_record.escola_id)

      next if unity.blank?

      grades = []
      classroom_record.series_regras.select { |serie| grades << serie.serie_id }
      grade = grade(grades.compact.first)

      next if grade.blank?

      next if classroom_record.nome.nil?

      (
        classroom(classroom_record.id) ||
        Classroom.new(api_code: classroom_record.id)
      ).tap do |classroom|
        old_name = classroom.description.try(:strip)
        new_name = classroom_record.nome.try(:strip)
        classroom.description = new_name
        classroom.unity = unity
        classroom.unity_code = classroom_record.escola_id
        classroom.period = classroom_record.turno_id
        classroom.year = classroom_record.ano
        classroom.max_students = classroom_record.max_aluno
        classroom.regent_api_code = classroom_record.ref_cod_regente

        if classroom.persisted? && classroom.period_changed? && classroom.period_was.present?
          update_period_dependents(classroom.id, classroom.period_was, classroom.period)
        end

        classroom.save!

        preload_classrooms_grades(classroom.id)

        grades_ids = []
        exam_rule_changed = false

        classroom_record.series_regras.each do |grade_exam_rule|
          grade = grade(grade_exam_rule.serie_id)
          exam_rule = exam_rule(grade_exam_rule.regra_avaliacao_id)

          next if grade.blank? || exam_rule.blank?

          grades_ids << grade.id

          (
            classrooms_grade(classroom.id, grade.id) ||
            ClassroomsGrade.new(classroom_id: classroom.id, grade_id: grade.id)
          ).tap do |classroom_grade|
            classroom_grade.exam_rule_id = exam_rule.id
            # Marca se uma série já existente trocou de regra — só nesse caso um lançamento
            # antigo pode ter ficado órfão. (Série nova não tem lançamento anterior.)
            exam_rule_changed ||= classroom_grade.persisted? && classroom_grade.exam_rule_id_changed?
            classroom_grade.save!
          end
        end

        destroy_old_grades(grades_ids, classroom.classrooms_grades, classroom_record.updated_at)

        discard_orphan_descriptive_exams(classroom) if exam_rule_changed

        update_label(classroom.id, new_name) if old_name != new_name

        classroom.discard_or_undiscard(classroom_record.deleted_at.present?)

        remove_current_classroom_id_in_user_selectors(classroom.id) if classroom_record.deleted_at.present?
      end
    end
  end

  def destroy_old_grades(grades_ids, classroom_grades, classroom_updated_at)
    return unless should_destroy_old_grades?(classroom_updated_at)

    classroom_grades.where.not(grade_id: grades_ids).destroy_all
  end

  # Reapontar uma série para uma regra com opinion_type diferente, numa turma que já tem
  # lançamentos de parecer, pode deixar esses lançamentos órfãos. Este método exclui os
  # órfãos: os pareceres cujo opinion_type não bate com nenhuma regra atual da turma (nem
  # com a diferenciada dela) — mesma régua do envio (DescriptiveExamPoster).
  def discard_orphan_descriptive_exams(classroom)
    valid_opinion_types = ClassroomsGrade.where(classroom_id: classroom.id)
                                         .includes(exam_rule: :differentiated_exam_rule)
                                         .flat_map { |classroom_grade|
                                           exam_rule = classroom_grade.exam_rule
                                           [exam_rule&.opinion_type, exam_rule&.differentiated_exam_rule&.opinion_type]
                                         }
                                         .compact.uniq
    return if valid_opinion_types.blank?

    Audited.audit_class.as_user('descriptive_exams_opinion_type_sync') do
      DescriptiveExam.where(classroom_id: classroom.id)
                     .where.not(opinion_type: valid_opinion_types)
                     .destroy_all
    end
  end

  # So deve destruir grades antigas se:
  # 1. For uma sincronizacao completa (full_synchronization), OU
  # 2. A turma foi modificada (updated_at >= modified_at), garantindo que todas as series foram retornadas na API
  def should_destroy_old_grades?(classroom_updated_at)
    return true if synchronization.full_synchronization?
    return true if @modified_at.blank?

    parsed_updated_at = Time.zone.parse(classroom_updated_at.to_s)
    parsed_updated_at >= @modified_at
  end

  def remove_current_classroom_id_in_user_selectors(classroom_id)
    Classroom.with_discarded.find_by(id: classroom_id).users.each do |user|
      user.update(current_classroom_id: nil, assumed_teacher_id: nil)
    end
  end

  def update_period_dependents(classroom_id, old_period, new_period)
    PeriodUpdaterWorker.perform_in(1.second, entity_id, classroom_id, old_period, new_period)
  end

  def update_label(classroom_id, new_name)
    label = Label.find_by(labelable_id: classroom_id)
    return if label.nil?

    label.name = new_name
    label.save!
  end
end
