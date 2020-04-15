class PopulateFieldOwnerTeacherId < ActiveRecord::Migration
  def change
    DailyFrequency.where('EXTRACT(year FROM frequency_date) = 2020')
                  .where(owner_teacher_id: nil)
                  .each do |daily_frequency|

      user_id = daily_frequency.audits.find_by(action: 'create')&.user_id

      next if user_id.blank?

      teacher_id = if user_id == 1
                     classroom_id = daily_frequency.classroom_id
                     discipline_id = daily_frequency.discipline_id

                     next if discipline_id.blank?

                     TeacherDisciplineClassroom.with_discarded.find_by(
                       year: 2020,
                       classroom_id: classroom_id,
                       discipline_id: discipline_id
                     )&.teacher_id
                   else
                     user = User.find(user_id)

                     user&.teacher_id
                   end

      next if teacher_id.blank?

      daily_frequency.update(owner_teacher_id: teacher_id)
    end
  end
end
