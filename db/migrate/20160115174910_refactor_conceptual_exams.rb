class RefactorConceptualExams < ActiveRecord::Migration[4.2]
  def change
    rename_table :conceptual_exams, :conceptual_exams_old

    create_table :conceptual_exams do |t|
      t.references :classroom, null: false, foreign_key: true
      t.references :school_calendar_step, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true
      t.date :recorded_at, null: false

      t.timestamps
    end

    add_index(
      :conceptual_exams,
      [:classroom_id, :school_calendar_step_id, :student_id],
      unique: true,
      name: :unique_index_on_conceptual_exams
    )

    create_table :conceptual_exam_values do |t|
      t.references :conceptual_exam, null: false, foreign_key: true
      t.references :discipline, null: false, foreign_key: true
      t.decimal :value, null: true

      t.timestamps
    end

    add_index(
      :conceptual_exam_values,
      [:conceptual_exam_id, :discipline_id],
      unique: true,
      name: :unique_index_on_conceptual_exam_values
    )

    # Delete duplicated records
    execute <<-SQL
      DELETE FROM conceptual_exam_students WHERE id IN (
        SELECT s1.id FROM conceptual_exam_students s1
          LEFT JOIN conceptual_exams_old c1 ON c1.id = s1.conceptual_exam_id
          WHERE (
            SELECT COUNT(*)
              FROM conceptual_exam_students s2
              LEFT JOIN conceptual_exams_old c2 ON c2.id = s2.conceptual_exam_id
              WHERE c2.classroom_id = c1.classroom_id AND c2.discipline_id = c1.discipline_id AND c2.school_calendar_step_id = c1.school_calendar_step_id AND s2.student_id = s1.student_id AND s2.updated_at > s1.updated_at
          ) > 0
      );
    SQL

    create_table :conceptual_exams_temp, temporary: true do |t|
      t.references :classroom, null: false
      t.references :discipline, null: false
      t.references :school_calendar_step, null: false
      t.references :student, null: false
      t.decimal :value, null: true

      t.timestamps
    end

    add_index(
      :conceptual_exams_temp,
      [:classroom_id, :discipline_id, :school_calendar_step_id, :student_id],
      unique: true,
      name: :unique_index_conceptual_exams_temp
    )

    # Migrate data to the temporary table
    execute <<-SQL
      INSERT INTO conceptual_exams_temp (classroom_id, discipline_id, school_calendar_step_id, student_id, value, created_at, updated_at)
        SELECT c.classroom_id, c.discipline_id, c.school_calendar_step_id, s.student_id, s.value, s.created_at, s.updated_at
          FROM conceptual_exam_students s
          LEFT JOIN conceptual_exams_old c ON c.id = s.conceptual_exam_id;
    SQL

    drop_table :conceptual_exam_students
    drop_table :conceptual_exams_old

    # Migrate data to the new conceptual_exams table
    execute <<-SQL
      INSERT INTO conceptual_exams (classroom_id, school_calendar_step_id, student_id, recorded_at, created_at, updated_at)
        SELECT
          t.classroom_id,
          t.school_calendar_step_id,
          t.student_id,
          (
        	  SELECT s.end_at
        	    FROM school_calendar_steps s
        	    WHERE s.id = t.school_calendar_step_id
          ) AS recorded_at,
          (
           SELECT t2.created_at
             FROM conceptual_exams_temp t2
             WHERE t2.classroom_id = t.classroom_id AND t2.school_calendar_step_id = t.school_calendar_step_id AND t2.student_id = t.student_id
             ORDER BY t2.created_at ASC LIMIT 1
          ) AS created_at,
          (
            SELECT t2.created_at
              FROM conceptual_exams_temp t2
              WHERE t2.classroom_id = t.classroom_id AND t2.school_calendar_step_id = t.school_calendar_step_id AND t2.student_id = t.student_id
              ORDER BY t2.created_at ASC LIMIT 1
          ) AS updated_at
          FROM conceptual_exams_temp t
          GROUP BY t.classroom_id, t.school_calendar_step_id, t.student_id;
    SQL

    # Migrate data to the new conceptual_exam_values table
    execute <<-SQL
      INSERT INTO conceptual_exam_values (conceptual_exam_id, discipline_id, value, created_at, updated_at)
        SELECT
          (
            SELECT c.id
              FROM conceptual_exams c
              WHERE c.classroom_id = t.classroom_id AND c.school_calendar_step_id = t.school_calendar_step_id AND c.student_id = t.student_id
          ) as conceptual_exam_id,
          t.discipline_id,
          t.value,
          t.created_at,
          t.updated_at
          FROM conceptual_exams_temp t;
    SQL
  end
end
