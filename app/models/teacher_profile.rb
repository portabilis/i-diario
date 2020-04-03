class TeacherProfile < ActiveRecord::Base
  belongs_to :user, touch: true
  belongs_to :teacher
  belongs_to :user_role
  belongs_to :classroom
  belongs_to :discipline
  belongs_to :unity

  has_one :role, through: :user_role

  has_many :users, dependent: :nullify

  def self.generate(user)
    transaction do
      teacher = user.teacher

      teacher.unities.each do |unity|
        user_role = user.user_roles.find_by(unity_id: unity.id)
        years = user.available_years(unity)
        years.each do |year_hash|
          year = year_hash[:id]

          classrooms = teacher.classrooms.by_year(year).ordered.uniq
          classrooms.each do |classroom|
            disciplines = classroom.disciplines.by_teacher_id(teacher.id).ordered
            disciplines.each do |discipline|
              create!(
                user_role: user_role,
                classroom_id: classroom.id,
                discipline_id: discipline.id,
                year: year,
                unity_id: classroom.unity_id,
                teacher_id: teacher.id,
                user_id: user.id
              )
            end
          end
        end
      end
    end
  end

end
