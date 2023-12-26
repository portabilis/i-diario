class NullifyInvalidCurrentDisciplineIdReferenceFromUsers < ActiveRecord::Migration[4.2]
  def change
    user_current_discipline_ids = User.pluck(:current_discipline_id).uniq.compact
    discipline_ids = Discipline.where(id: user_current_discipline_ids).pluck(:id).uniq

    not_found = user_current_discipline_ids - discipline_ids

    User.where(current_discipline_id: not_found).update_all(current_discipline_id: nil) if not_found.present?
  end
end
