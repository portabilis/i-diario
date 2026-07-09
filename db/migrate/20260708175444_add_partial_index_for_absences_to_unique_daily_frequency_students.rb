class AddPartialIndexForAbsencesToUniqueDailyFrequencyStudents < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  # Índice parcial para a busca de ausências (present = false) por intervalo de datas,
  # usada de forma recorrente pelo InfrequencyTrackingNotifier. Sem ele o Postgres
  # recorre a Parallel Seq Scan na tabela inteira.
  def up
    add_index :unique_daily_frequency_students, :frequency_date,
              where: 'present = false',
              name: 'idx_freq_students_absences_date',
              algorithm: :concurrently
  end

  def down
    remove_index :unique_daily_frequency_students,
                 name: 'idx_freq_students_absences_date',
                 algorithm: :concurrently
  end
end
