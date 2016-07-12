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

    it "should validate uniqueness of user and unity" do
      user_role = UserRole.new(user: users(:john_doe), unity: unities(:escola_y))

      subject.user_roles = [user_role, user_role]

      subject.valid?

      expect(subject.errors[:user_roles]).to eq ["não é válido"]
    end

    it "should validate permissions must match access level" do
      subject.access_level = AccessLevel::TEACHER

      subject.permissions.build(feature: Features::USERS, permission: Permissions::CHANGE)

      subject.valid?

      expect(subject.errors[:permissions]).to eq ["Funcionalidade Usuários não pertence ao nível de acesso Professor."]
    end
  end

  describe "#to_s" do
    it "returns name" do
      subject.name = "administrador"
      subject.access_level = AccessLevel::PARENT

      expect(subject.to_s).to eq "administrador - Nível: Pais"
    end
  end
end
