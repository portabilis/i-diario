class AddInitialValueToStepTypeDescription < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE school_calendar_classrooms
      SET step_type_description =
        CASE (SELECT COUNT(*) FROM school_calendar_classroom_steps WHERE school_calendar_classroom_id = school_calendar_classrooms.id)
        WHEN 1 THEN 'Anual'
        WHEN 2 THEN 'Semestre'
        WHEN 3 THEN 'Trimestre'
        WHEN 4 THEN 'Bimestre'
        ELSE 'Etapa'
        END;

      UPDATE school_calendars
      SET step_type_description =
        CASE (SELECT COUNT(*) FROM school_calendar_steps WHERE school_calendar_id = school_calendars.id)
        WHEN 1 THEN 'Anual'
        WHEN 2 THEN 'Semestre'
        WHEN 3 THEN 'Trimestre'
        WHEN 4 THEN 'Bimestre'
        ELSE 'Etapa'
        END;
    SQL
  end
end
