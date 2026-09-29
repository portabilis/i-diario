class RemoveSingleMedicationFromIndividualizedEducationalPlans < ActiveRecord::Migration[5.0]
  # Os valores já estão em iep_medications (MoveMedicationToIepMedications). O down recria as
  # colunas vazias; para repovoá-las, desfazer também aquela migration.
  def change
    remove_column :individualized_educational_plans, :medication_name, :string
    remove_column :individualized_educational_plans, :medication_dosage, :string
    remove_column :individualized_educational_plans, :medication_schedule, :string
  end
end
