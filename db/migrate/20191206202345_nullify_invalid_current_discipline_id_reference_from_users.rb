class NullifyInvalidCurrentDisciplineIdReferenceFromUsers < ActiveRecord::Migration
  def change
    User.all.each do |user|
      current_discipline_id = user.current_discipline_id

      if current_discipline_id.present? && !Discipline.find_by(id: current_discipline_id)
        user.update(current_discipline_id: nil)
      end
    end
  end
end
