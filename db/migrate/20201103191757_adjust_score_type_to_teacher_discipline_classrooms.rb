class AdjustScoreTypeToTeacherDisciplineClassrooms < ActiveRecord::Migration
  def change
    execute <<-SQL
      DO $$
        DECLARE numeric_score_relation_ids INTEGER[];
        DECLARE conceptual_score_relation_ids INTEGER[];
      BEGIN
        numeric_score_relation_ids := ARRAY(
          SELECT id
            FROM teacher_discipline_classrooms
           WHERE score_type = '1'
        );

        conceptual_score_relation_ids := ARRAY(
          SELECT id
            FROM teacher_discipline_classrooms
           WHERE score_type = '2'
        );

        UPDATE teacher_discipline_classrooms
           SET score_type = '1'
         WHERE id = ANY(conceptual_score_relation_ids);

        UPDATE teacher_discipline_classrooms
           SET score_type = '2'
         WHERE id = ANY(numeric_score_relation_ids);
      END$$;
    SQL
  end
end
