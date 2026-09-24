class AddClassroomAndAutomaticToIeducarApiExamPostings < ActiveRecord::Migration[5.0]
  # classroom_id restringe o envio a uma turma (nulo = todas as turmas do professor, como no
  # envio manual); automatic separa os envios disparados pelo registro de frequência dos feitos
  # pela tela, porque a base incremental de um nunca pode ser usada pelo outro.
  #
  # A tabela deixa de ser log de envio manual e passa a receber uma linha por registro de
  # frequência, então índice e chave estrangeira entram sem bloquear escrita.
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = 'fk_ieducar_api_exam_postings_classroom_id'.freeze

  def up
    add_column :ieducar_api_exam_postings, :classroom_id, :integer
    add_column :ieducar_api_exam_postings, :automatic, :boolean, default: false, null: false

    add_index :ieducar_api_exam_postings, :classroom_id, algorithm: :concurrently

    # Rails 5.0 não expõe validate: false em add_foreign_key. NOT VALID evita o scan da tabela sob
    # ACCESS EXCLUSIVE; a validação depois toma um lock que não bloqueia leitura nem escrita.
    execute <<~SQL
      ALTER TABLE ieducar_api_exam_postings
        ADD CONSTRAINT #{FOREIGN_KEY_NAME}
        FOREIGN KEY (classroom_id) REFERENCES classrooms (id) NOT VALID
    SQL

    execute "ALTER TABLE ieducar_api_exam_postings VALIDATE CONSTRAINT #{FOREIGN_KEY_NAME}"
  end

  def down
    execute "ALTER TABLE ieducar_api_exam_postings DROP CONSTRAINT IF EXISTS #{FOREIGN_KEY_NAME}"

    remove_column :ieducar_api_exam_postings, :automatic
    remove_column :ieducar_api_exam_postings, :classroom_id
  end
end
