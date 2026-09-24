class AddMedicationAndFamilyEnvironmentToIndividualizedEducationalPlans < ActiveRecord::Migration[5.0]
  def change
    # Seção 3 — Equipe de suporte. Campos opcionais: uses_medication é tri-state
    # (NULL = não respondido, distinto de "Não"), por isso sem default.
    add_column :individualized_educational_plans, :uses_medication, :boolean
    add_column :individualized_educational_plans, :medication_name, :string
    add_column :individualized_educational_plans, :medication_dosage, :string
    add_column :individualized_educational_plans, :medication_schedule, :string
    add_column :individualized_educational_plans, :medication_notes, :text
    add_column :individualized_educational_plans, :family_environment_characteristics, :text
  end
end
