class Discipline < ActiveRecord::Base
  acts_as_copy_target

  audited

  belongs_to :knowledge_area
  has_many :teacher_discipline_classrooms, dependent: :destroy
  has_and_belongs_to_many :absence_justifications

  validates :description, :api_code, :knowledge_area_id, presence: true
  validates :api_code, uniqueness: true

  scope :by_unity_id, lambda { |unity_id| by_unity_id(unity_id) }
  scope :by_teacher_id, lambda { |teacher_id| joins(:teacher_discipline_classrooms).where(teacher_discipline_classrooms: { teacher_id: teacher_id }).uniq }

  # It works only when the query chain has join with
  # teacher_discipline_classrooms. Using scopes like by_teacher_id or
  # by_classroom for example.
  scope :by_score_type, lambda { |score_type, student_id = nil|
    scoped = joins(teacher_discipline_classrooms: { classroom: :exam_rule })
    if student_id && Student.find(student_id).try(:uses_differentiated_exam_rule)
      exam_rules = ExamRule.arel_table.alias('exam_rules_classrooms')

      differentiated_exam_rules = ExamRule.arel_table.alias('differentiated_exam_rules')
        scoped.joins(
          arel_table.join(differentiated_exam_rules, Arel::Nodes::OuterJoin).
            on(differentiated_exam_rules[:id].eq(exam_rules[:differentiated_exam_rule_id])).join_sources
        ).where(
          exam_rules[:score_type].eq(score_type).or(
            exam_rules[:score_type].eq(ScoreTypes::NUMERIC_AND_CONCEPT).
            and(TeacherDisciplineClassroom.arel_table[:score_type].eq(score_type))
          ).or(
            differentiated_exam_rules[:score_type].eq(score_type)
          )
        ).uniq
    else
      scoped.where(
        ExamRule.arel_table[:score_type].eq(score_type).
        or(
          ExamRule.arel_table[:score_type].eq(ScoreTypes::NUMERIC_AND_CONCEPT).
          and(TeacherDisciplineClassroom.arel_table[:score_type].eq(score_type))
        )
      ).uniq
    end
  }

  scope :by_grade, lambda { |grade| by_grade(grade) }
  scope :by_classroom, lambda { |classroom| by_classroom(classroom) }
  scope :by_teacher_and_classroom, lambda { |teacher_id, classroom_id| joins(:teacher_discipline_classrooms).where(teacher_discipline_classrooms: { teacher_id: teacher_id, classroom_id: classroom_id }).uniq }
  scope :ordered, -> { order(arel_table[:description].asc) }
  scope :order_by_sequence, -> { order(arel_table[:sequence].asc) }
  scope :by_description, lambda { |description|
    joins(:knowledge_area)
      .where(<<-SQL, description: "%#{description}%")
        CASE
            WHEN knowledge_areas.group_descriptors THEN unaccent(knowledge_areas.description) ILIKE unaccent(:description)
            ELSE unaccent(disciplines.description) ILIKE unaccent(:description)
        END
      SQL
  }

  def to_s
    if knowledge_area.group_descriptors
      knowledge_area.description
    else
      description
    end
  end

  def self.grouped_by_knowledge_area
    joins(:knowledge_area)
      .select(
        <<-SQL
          disciplines.id,
          disciplines.id discipline_id,
          knowledge_areas.group_descriptors,
          knowledge_area_id,
          CASE
              WHEN knowledge_areas.group_descriptors THEN knowledge_areas.description
              ELSE disciplines.description
          END AS description
        SQL
      )
      .order('description asc')
      .to_a.group_by { |d| [d.group_descriptors, d.knowledge_area_id] }.map do |group, disciplines|
        if group[0]
          disciplines.first
        else
          disciplines
        end
      end.flatten
  end

  private

  def self.by_unity_id(unity_id)
    joins(:teacher_discipline_classrooms).joins(
        arel_table.join(Classroom.arel_table)
          .on(
            Classroom.arel_table[:id]
              .eq(TeacherDisciplineClassroom.arel_table[:classroom_id])
          )
          .join_sources
      )
      .where(classrooms: { unity_id: unity_id })
      .uniq
  end

  def self.by_grade(grade)
    joins(:teacher_discipline_classrooms).joins(
        arel_table.join(Classroom.arel_table)
          .on(
            Classroom.arel_table[:id]
              .eq(TeacherDisciplineClassroom.arel_table[:classroom_id])
          )
          .join_sources
      )
      .where(classrooms: { grade_id: grade })
      .uniq
  end

  def self.by_classroom(classroom)
    joins(:teacher_discipline_classrooms).where(
        teacher_discipline_classrooms: { classroom_id: classroom }
      )
      .uniq
  end
end
