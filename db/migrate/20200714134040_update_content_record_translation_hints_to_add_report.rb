class UpdateContentRecordTranslationHintsToAddReport < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      UPDATE translations
         SET hint = 'Altera o nome do módulo; o caminho da tela de Registros de conteúdos por áreas de conhecimento; título da listagem e do novo cadastro; cópia de registros; relatórios'
       WHERE key IN (
               'activerecord.attributes.discipline_content_record.contents',
               'activerecord.attributes.knowledge_area_content_record.contents'
             );
    SQL
  end

  def down
    execute <<-SQL
      UPDATE translations
         SET hint = 'Altera o nome do módulo; o caminho da tela de Registros de conteúdos por áreas de conhecimento; título da listagem e do novo cadastro; cópia de registros'
       WHERE key IN (
               'activerecord.attributes.discipline_content_record.contents',
               'activerecord.attributes.knowledge_area_content_record.contents'
             );
    SQL
  end
end
