class RefactorTeachingPlans < ActiveRecord::Migration[4.2]
  def change
    rename_table :teaching_plans, :teaching_plans_old

    create_table :teaching_plans do |t|
      t.integer :year, null: false
      t.references :unity, null: false, index: true, foreign_key: true
      t.references :grade, null: false, index: true, foreign_key: true
      t.string :school_term_type, null: false
      t.string :school_term, null: true
      t.text :objectives
      t.text :content
      t.text :methodology
      t.text :evaluation
      t.text :references

      t.timestamps
    end

    create_table :discipline_teaching_plans do |t|
      t.references :teaching_plan, null: false, foreign_key: true
      t.references :discipline, null: false, foreign_key: true

      t.timestamps
    end

    add_index(
      :discipline_teaching_plans,
      [:teaching_plan_id, :discipline_id],
      unique: true,
      name: :idx_discipline_teaching_plans_on_teaching_plan_and_discipline
    )

    create_table :knowledge_area_teaching_plans do |t|
      t.references :teaching_plan, null: false, foreign_key: true

      t.timestamps
    end

    add_index(:discipline_teaching_plans, :teaching_plan_id, unique: true)

    create_table :knowledge_area_teaching_plan_knowledge_areas do |t|
      t.references :knowledge_area_teaching_plan, null: false
      t.references :knowledge_area, null: false

      t.timestamps
    end

    add_foreign_key(
      :knowledge_area_teaching_plan_knowledge_areas,
      :knowledge_area_teaching_plans,
      name: :ka_teaching_p_knowledge_areas_knowledge_area_teaching_plan_fk
    )

    add_foreign_key(
      :knowledge_area_teaching_plan_knowledge_areas,
      :knowledge_areas,
      name: :knowledge_area_teaching_plan_knowledge_areas_knowledge_area_fk
    )

    add_index(
      :knowledge_area_teaching_plan_knowledge_areas,
      [:knowledge_area_teaching_plan_id, :knowledge_area_id],
      unique: true,
      name: :idx_ka_tp_ka_on_k_area_teaching_plan_id_and_knowledge_area_id
    )

    create_table :teaching_plans_temp, temporary: true do |t|
      t.integer :year, null: false
      t.references :unity, null: true
      t.references :grade, null: false
      t.references :discipline, null: false
      t.string :school_term_type, null: false
      t.string :school_term, null: true
      t.text :objectives
      t.text :content
      t.text :methodology
      t.text :evaluation
      t.text :references

      t.timestamps
    end

    # Migrate data to the temporary table
    execute <<-SQL
      INSERT INTO teaching_plans_temp (
        year,
        unity_id,
        grade_id,
        discipline_id,
        school_term_type,
        school_term, objectives,
        content, methodology,
        evaluation,
        "references",
        created_at,
        updated_at
      )
        SELECT
          t.year,
          c.unity_id,
          c.grade_id,
          t.discipline_id,
          t.school_term_type,
          t.school_term,
          t.objectives,
          t.content,
          t.methodology,
          t.evaluation,
          t.references,
          t.created_at,
          t.updated_at
          FROM teaching_plans_old t
          LEFT JOIN classrooms c ON c.id = t.classroom_id;
    SQL

    drop_table :teaching_plans_old

    # Migrate data to the new teaching_plans table
    execute <<-SQL
      INSERT INTO teaching_plans (
          year,
          unity_id,
          grade_id,
          school_term_type,
          school_term, objectives,
          content, methodology,
          evaluation,
          "references",
          created_at,
          updated_at
        )
          SELECT
            t.year,
            t.unity_id,
            t.grade_id,
            t.school_term_type,
            t.school_term,
            t.objectives,
            t.content,
            t.methodology,
            t.evaluation,
            t.references,
            t.created_at,
            t.updated_at
            FROM teaching_plans_temp t;
    SQL

    # Migrate data to the new discipline_teaching_plans table
    execute <<-SQL
      INSERT INTO discipline_teaching_plans (
        teaching_plan_id,
        discipline_id,
        created_at,
        updated_at
      )
      SELECT
        t.id,
        tt.discipline_id,
        t.created_at,
        t.updated_at
        FROM teaching_plans_temp tt
        LEFT JOIN teaching_plans t
          ON t.year = tt.year
          AND t.unity_id = tt.unity_id
          AND t.grade_id = tt.grade_id
          AND t.school_term_type = tt.school_term_type
          AND t.school_term = tt.school_term
          AND t.created_at = tt.created_at
          AND t.updated_at = tt.updated_at;
    SQL

    # Migrate permissions
    execute <<-SQL
      UPDATE role_permissions SET feature = 'discipline_teaching_plans'
        WHERE feature = 'teaching_plans';

      INSERT INTO role_permissions (
        role_id,
        feature,
        permission,
        created_at,
        updated_at
      )
        SELECT
          role_id,
          'knowledge_area_teaching_plans' AS feature,
          permission,
          created_at,
          updated_at
          FROM role_permissions
          WHERE feature = 'discipline_teaching_plans';
    SQL
  end
end
