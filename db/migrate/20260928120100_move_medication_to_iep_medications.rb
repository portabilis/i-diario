class MoveMedicationToIepMedications < ActiveRecord::Migration[5.0]
  # SQL direto: a cópia não passa por callback nem auditoria, e o model já ignora as colunas
  # de origem. NOT EXISTS mantém a migration reexecutável sem duplicar linhas.
  #
  # Plano com só dosagem ou horário preenchidos gera linha sem nome: o dado é preservado, e a
  # validação do model pede o nome no próximo salvamento.
  def up
    execute <<-SQL
      INSERT INTO iep_medications (individualized_educational_plan_id, name, dosage, schedule,
                                   created_at, updated_at)
      SELECT plans.id,
             NULLIF(TRIM(plans.medication_name), ''),
             NULLIF(TRIM(plans.medication_dosage), ''),
             NULLIF(TRIM(plans.medication_schedule), ''),
             NOW(), NOW()
        FROM individualized_educational_plans plans
       WHERE (COALESCE(TRIM(plans.medication_name), '') <> ''
              OR COALESCE(TRIM(plans.medication_dosage), '') <> ''
              OR COALESCE(TRIM(plans.medication_schedule), '') <> '')
         AND NOT EXISTS (
           SELECT 1 FROM iep_medications meds
            WHERE meds.individualized_educational_plan_id = plans.id
         )
    SQL

    # Medicamento preenchido sem resposta na pergunta equivale a "Sim". Um "Não" explícito
    # prevalece: a linha copiada fica oculta no formulário e é descartada no próximo salvamento.
    execute <<-SQL
      UPDATE individualized_educational_plans plans
         SET uses_medication = TRUE
       WHERE plans.uses_medication IS NULL
         AND EXISTS (
           SELECT 1 FROM iep_medications meds
            WHERE meds.individualized_educational_plan_id = plans.id
         )
    SQL
  end

  # Devolve o primeiro medicamento às colunas antigas. O "Sim" gravado no up não é desfeito:
  # depois da migração ele é indistinguível de um "Sim" respondido pelo usuário.
  def down
    execute <<-SQL
      UPDATE individualized_educational_plans plans
         SET medication_name = first_medication.name,
             medication_dosage = first_medication.dosage,
             medication_schedule = first_medication.schedule
        FROM (
          SELECT DISTINCT ON (individualized_educational_plan_id)
                 individualized_educational_plan_id, name, dosage, schedule
            FROM iep_medications
           ORDER BY individualized_educational_plan_id, id
        ) first_medication
       WHERE first_medication.individualized_educational_plan_id = plans.id
    SQL

    execute 'DELETE FROM iep_medications'
  end
end
