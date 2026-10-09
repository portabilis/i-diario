# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

RSpec.describe StudentsDisplaySequencer, type: :service do
  def student(dependence:)
    OpenStruct.new(dependence: dependence, display_sequence: nil)
  end

  describe '.call' do
    it 'numbers regular students sequentially starting at 1' do
      students = [student(dependence: false), student(dependence: false), student(dependence: false)]

      described_class.call(students)

      expect(students.map(&:display_sequence)).to eq([1, 2, 3])
    end

    it 'numbers dependence students with their own sequence starting at 1' do
      students = [student(dependence: true), student(dependence: true)]

      described_class.call(students)

      expect(students.map(&:display_sequence)).to eq([1, 2])
    end

    it 'keeps independent sequences for regular and dependence students, preserving order' do
      regular_a = student(dependence: false)
      regular_b = student(dependence: false)
      dependence_a = student(dependence: true)
      dependence_b = student(dependence: true)
      students = [regular_a, dependence_a, regular_b, dependence_b]

      described_class.call(students)

      expect(regular_a.display_sequence).to eq(1)
      expect(regular_b.display_sequence).to eq(2)
      expect(dependence_a.display_sequence).to eq(1)
      expect(dependence_b.display_sequence).to eq(2)
    end

    it 'returns the same students collection' do
      students = [student(dependence: false)]

      expect(described_class.call(students)).to eq(students)
    end

    it 'does nothing with an empty collection' do
      expect(described_class.call([])).to eq([])
    end
  end
end
