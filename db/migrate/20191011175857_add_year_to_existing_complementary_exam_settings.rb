class AddYearToExistingComplementaryExamSettings < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DO $$
        DECLARE _complementary_exam_setting RECORD;
        DECLARE _year INTEGER;
      BEGIN
        FOR _complementary_exam_setting IN (
          SELECT id
            FROM complementary_exam_settings
        ) LOOP
          IF EXISTS (
            SELECT 1
              FROM complementary_exams
            WHERE complementary_exam_setting_id = _complementary_exam_setting.id
          ) THEN
            SELECT CAST (
              EXTRACT (
                YEAR FROM (
                  SELECT recorded_at FROM complementary_exams
                   WHERE complementary_exam_setting_id = _complementary_exam_setting.id
                   LIMIT 1
                )
              )
              AS INTEGER
            ) INTO _year;
          ELSE
            SELECT CAST (EXTRACT (YEAR FROM NOW()) AS INTEGER) INTO _year;
          END IF;

          UPDATE complementary_exam_settings
             SET year = _year
           WHERE id = _complementary_exam_setting.id;
        END LOOP;
      END$$;
    SQL
  end
end
