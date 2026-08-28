class AddClassroomAndAutomaticToIeducarApiExamPostings < ActiveRecord::Migration[5.0]
  # classroom_id restringe o envio a uma turma (nulo = todas as turmas do professor, como no
  # envio manual); automatic separa os envios disparados pelo registro de frequência dos
  # feitos pela tela, porque a base incremental de um nunca pode ser usada pelo outro.
  def change
    add_column :ieducar_api_exam_postings, :classroom_id, :integer
    add_index :ieducar_api_exam_postings, :classroom_id
    add_foreign_key :ieducar_api_exam_postings, :classrooms, column: :classroom_id

    add_column :ieducar_api_exam_postings, :automatic, :boolean, default: false, null: false
  end
end
