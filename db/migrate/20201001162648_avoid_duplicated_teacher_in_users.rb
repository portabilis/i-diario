class AvoidDuplicatedTeacherInUsers < ActiveRecord::Migration[4.2]
  def change
    teacher_ids = User.group(:teacher_id).having('count(teacher_id) > 1').pluck(:teacher_id)
    teacher_ids.each do |teacher_id|
      users = User.joins(:teacher)
        .select(
          <<-SQL
            users.id,
            users.email,
            users.teacher_id,
            users.fullname,
            users.last_sign_in_at,
            (SELECT TRUE
            FROM roles
            INNER JOIN user_roles ON user_roles.role_id = roles.id
            WHERE user_id = users.id
              AND access_level = 'teacher' limit 1) is_teacher,
            status = 'active' is_active,
            (
              select count(1)
              from ieducar_api_exam_postings
              where ieducar_api_exam_postings.author_id = users.id
                    and ieducar_api_exam_postings.teacher_id = users.teacher_id
            ) exam_posting_count,
            (teachers.name = users.fullname) equal_name,
            sign_in_count > 0 was_logged,
            email ilike '%portabilis%' portabilis
          SQL
        ).order(
          <<-SQL
              portabilis asc,
              is_active desc NULLS last,
              is_teacher desc NULLS last,
              was_logged desc,
              equal_name desc,
              exam_posting_count desc,
              last_sign_in_at DESC NULLS LAST;
          SQL
        ).where(teacher_id: teacher_id).to_a

      users.each_with_index do |user, index|
        next if index.zero?

        user.teacher_id = nil
        user.without_auditing do
          user.save!(validate: false)
        end
      end
    end
  end
end
