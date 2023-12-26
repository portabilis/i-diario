class KnowledgeAreaTeachingPlan < ApplicationRecord
  include Audit
  include TeacherRelationable
  include Translatable

  teacher_relation_columns only: :knowledge_areas

  acts_as_copy_target

  audited
  has_associated_audits

  belongs_to :teaching_plan, dependent: :destroy
  has_many :knowledge_area_teaching_plan_knowledge_areas, dependent: :destroy
  has_many :knowledge_areas, through: :knowledge_area_teaching_plan_knowledge_areas

  delegate :contents, to: :teaching_plan
  delegate :objectives, to: :teaching_plan

  accepts_nested_attributes_for :teaching_plan

  scope :by_year, ->(year) { joins(:teaching_plan).where(teaching_plans: { year: year }) }
  scope :by_unity, ->(unity) { joins(:teaching_plan).where(teaching_plans: { unity_id: unity }) }
  scope :by_grade, ->(grade) { joins(:teaching_plan).where(teaching_plans: { grade_id: grade }) }
  scope :by_school_term_type_id, lambda { |school_term_type_id|
    joins(:teaching_plan).where(teaching_plans: { school_term_type_id: school_term_type_id })
  }
  scope :by_school_term_type_step_id, lambda { |school_term_type_step_id|
    joins(:teaching_plan).where(teaching_plans: { school_term_type_step_id: school_term_type_step_id })
  }
  scope :by_knowledge_area, ->(knowledge_area) { by_knowledge_area(knowledge_area) }
  scope :by_teacher_id, ->(teacher_id) { joins(:teaching_plan).where(teaching_plans: { teacher_id: teacher_id }) }
  scope :by_other_teacher_id, lambda { |teacher_id|
    joins(:teaching_plan).where.not(teaching_plans: { teacher_id: [teacher_id, nil] })
  }
  scope :by_secretary, -> { joins(:teaching_plan).where(teaching_plans: { teacher_id: nil }) }
  scope :by_author, lambda { |author_type, current_teacher_id|
    if author_type == PlansAuthors::MY_PLANS
      joins(:teaching_plan).merge(TeachingPlan.where(teacher_id: current_teacher_id))
    else
      joins(:teaching_plan).merge(TeachingPlan.where.not(teacher_id: current_teacher_id))
    end
  }
  scope :order_by_school_term_type_step, lambda {
    joins(:teaching_plan).order('teaching_plans.school_term_type_step_id IS NULL')
  }

  scope :order_by_grades, lambda {
    joins(teaching_plan: :grade).order(Grade.arel_table[:description].desc)
  }

  validates :teaching_plan, presence: true
  validates :knowledge_area_ids, presence: true

  def optional_teacher
    true
  end

  def knowledge_area_ids
    knowledge_areas.collect(&:id).join(',')
  end

  private

  def self.by_teacher(teacher)
    joins(:teaching_plan).joins(:knowledge_area_teaching_plan_knowledge_areas)
      .joins(
        arel_table.join(Discipline.arel_table, Arel::Nodes::OuterJoin)
          .on(
            Discipline.arel_table[:knowledge_area_id]
              .eq(KnowledgeAreaTeachingPlanKnowledgeArea.arel_table[:knowledge_area_id])
          )
          .join_sources
      )
      .joins(
        arel_table.join(TeacherDisciplineClassroom.arel_table, Arel::Nodes::OuterJoin)
          .on(
            TeacherDisciplineClassroom.arel_table[:discipline_id]
              .eq(Discipline.arel_table[:id])
            .and(TeachingPlan.arel_table[:year]
              .eq(TeacherDisciplineClassroom.arel_table[:year]))
          )
          .join_sources
      )
      .joins(
        arel_table.join(Classroom.arel_table, Arel::Nodes::OuterJoin)
          .on(
            Classroom.arel_table[:grade_id]
              .eq(TeachingPlan.arel_table[:grade_id])
              .and(
                Classroom.arel_table[:id]
                  .eq(TeacherDisciplineClassroom.arel_table[:classroom_id])
              )
          )
          .join_sources
      )
      .where(TeacherDisciplineClassroom.arel_table[:teacher_id]
              .eq(teacher)
            .and(TeacherDisciplineClassroom.arel_table[:active]
              .eq('t')))
      .distinct
  end

  def self.by_knowledge_area(knowledge_area)
    joins(:knowledge_area_teaching_plan_knowledge_areas)
      .where(
        knowledge_area_teaching_plan_knowledge_areas: {
          knowledge_area_id: knowledge_area
        }
      )
  end
end
