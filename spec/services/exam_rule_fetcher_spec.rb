require 'rails_helper'

RSpec.describe ExamRuleFetcher, type: :service do
  let(:differentiated_exam_rule) { create(:exam_rule) }
  let(:exam_rule) { create(:exam_rule) }
  let(:classroom) { create(:classroom, exam_rule: exam_rule) }
  let(:student) { create(:student) }

  subject do
    described_class.new(classroom, student)
  end

  context 'student uses differentiated exam rule' do
    before do
      student.uses_differentiated_exam_rule = true
    end

    context 'exam_rule has differentiated exam rule' do
      before do
        exam_rule.differentiated_exam_rule = differentiated_exam_rule
      end

      it 'return differentiated exam rule' do
        expect(subject.fetch).to be(differentiated_exam_rule)
      end
    end

    context 'exam_rule hasnt differentiated exam rule' do
      before do
        exam_rule.differentiated_exam_rule = nil
      end

      it 'return classroom exam rule' do
        expect(subject.fetch).to be(exam_rule)
      end
    end
  end

  context 'student doest use differentiated exam rule' do
    before do
      student.uses_differentiated_exam_rule = false
    end

    context 'exam_rule has differentiated exam rule' do
      before do
        exam_rule.differentiated_exam_rule = differentiated_exam_rule
      end

      it 'return classroom exam rule' do
        expect(subject.fetch).to be(exam_rule)
      end
    end

    context 'exam_rule hasnt differentiated exam rule' do
      before do
        exam_rule.differentiated_exam_rule = nil
      end

      it 'return classroom exam rule' do
        expect(subject.fetch).to be(exam_rule)
      end
    end
  end
end
