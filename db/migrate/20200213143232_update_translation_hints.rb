class UpdateTranslationHints < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      UPDATE translations SET hint = 'Altera o nome do módulo; o caminho da tela de Registros de conteúdos por disciplina; título da listagem e do novo cadastro; cópia de registros' WHERE key = 'navigation.discipline_content_records';
      UPDATE translations SET hint = 'Altera o nome do módulo; o caminho da tela de Registros de conteúdos por áreas de conhecimento; título da listagem e do novo cadastro; cópia de registros';
      UPDATE translations SET hint = 'Altera o nome do módulo; o caminho da tela de Planos de aula por disciplina; título da listagem e do novo cadastro; cópia de planos' WHERE key = 'navigation.discipline_lesson_plans';
      UPDATE translations SET hint = 'Altera o nome do módulo; o caminho da tela de Planos de aula por área; título da listagem e do novo cadastro; cópia de planos' WHERE key = 'navigation.knowledge_area_lesson_plans';
    SQL
  end

  def down
    execute <<-SQL
      UPDATE translations SET hint = 'Altera o nome do módulo; o caminho da tela de Registros de conteúdos por disciplina; título da listagem e do novo cadastro' WHERE key = 'navigation.discipline_content_records';
      UPDATE translations SET hint = 'Altera o nome do módulo; o caminho da tela de Registros de conteúdos por áreas de conhecimento; título da listagem e do novo cadastro' WHERE key = 'navigation.knowledge_area_content_records';
      UPDATE translations SET hint = 'Altera o nome do módulo; o caminho da tela de Planos de aula por disciplina; título da listagem e do novo cadastro' WHERE key = 'navigation.discipline_lesson_plans';
      UPDATE translations SET hint = 'Altera o nome do módulo; o caminho da tela de Planos de aula por área; título da listagem e do novo cadastro' WHERE key = 'navigation.knowledge_area_lesson_plans';
    SQL
  end
end
