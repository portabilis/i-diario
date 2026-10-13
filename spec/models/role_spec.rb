# encoding: utf-8
require 'rails_helper'

RSpec.describe Role, :type => :model do
  context "Associations" do
    it { should belong_to :author }
    it { should have_many :permissions }
  end

  context "Validations" do
    it { should validate_presence_of :author }
    it { should validate_presence_of :name }

    it "should validate permissions must match access level" do
      subject.access_level = AccessLevel::TEACHER

      subject.permissions.build(feature: Features::USERS, permission: Permissions::CHANGE)

      subject.valid?

      expect(subject.errors[:base]).to eq ["Funcionalidade Usuários não pertence ao nível de acesso Professor."]
    end

    it "allows copy teaching plan permissions for teacher access level" do
      subject.access_level = AccessLevel::TEACHER

      subject.permissions.build(feature: Features::COPY_DISCIPLINE_TEACHING_PLAN, permission: Permissions::CHANGE)
      subject.permissions.build(feature: Features::COPY_KNOWLEDGE_AREA_TEACHING_PLAN, permission: Permissions::CHANGE)

      subject.valid?

      expect(subject.errors[:base]).to be_empty
    end
  end

  describe "#to_s" do
    it "returns name" do
      subject.name = "administrador"
      subject.access_level = AccessLevel::TEACHER

      expect(subject.to_s).to eq "administrador - Nível: Professor"
    end
  end
end
