require 'rails_helper'

RSpec.describe IndividualizedEducationalPlanIndexClassroomsQuery do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) { |example| entity.using_connection { example.run } }

  let(:classroom) { create(:classroom) }

  def enroll(student, target_classroom, left_at: '')
    cg = create(:classrooms_grade, classroom: target_classroom)
    se = create(:student_enrollment, student: student)
    create(:student_enrollment_classroom, student_enrollment: se, classrooms_grade: cg, left_at: left_at)
  end

  describe '#display_classrooms' do
    it 'maps the student to the accessible classroom where they are enrolled' do
      plan = create(:individualized_educational_plan)
      enroll(plan.student, classroom)

      result = described_class.new([plan], [classroom.id]).display_classrooms

      expect(result[plan.student_id]).to eq(classroom)
    end

    it 'falls back to the authoring classroom when the student no longer attends (authorship only)' do
      plan = create(:individualized_educational_plan)
      create(:iep_version, iep: plan, classroom: classroom, active: true, published_at: Time.current)

      result = described_class.new([plan], [classroom.id]).display_classrooms

      expect(result[plan.student_id]).to eq(classroom)
    end
  end

  describe '#editable_student_ids' do
    it 'includes only students currently attending an accessible classroom' do
      attending = create(:individualized_educational_plan)
      enroll(attending.student, classroom)
      transferred = create(:individualized_educational_plan)
      enroll(transferred.student, classroom, left_at: 1.day.ago.to_date.to_s)

      result = described_class.new([attending, transferred], [classroom.id]).editable_student_ids

      expect(result).to contain_exactly(attending.student_id)
    end
  end
end
