class AddCurriculumAdaptationToTranslations < ActiveRecord::Migration[5.0]
  def change
    execute <<-SQL
      insert into translations(key, label, translation, "group", subgroup, hint, "order", created_at, updated_at) values ('navigation.curriculum_adaptation_by_discipline', 'Adaptação Curricular (por disciplina)', '', 'lesson_plans', 'fields', 'Altera a nomenclatura do campo Adaptação Curricular dentro do cadastro de Planos de aula por disciplina', 39, now(), now());
      insert into translations(key, label, translation, "group", subgroup, hint, "order", created_at, updated_at) values ('navigation.curriculum_adaptation_by_knowledge_area', 'Adaptação Curricular (por área)', '', 'lesson_plans', 'fields', 'Altera a nomenclatura do campo Adaptação Curricular dentro do cadastro de Planos de aula por áreas de conhecimento', 40, now(), now());
    SQL
  end
end
