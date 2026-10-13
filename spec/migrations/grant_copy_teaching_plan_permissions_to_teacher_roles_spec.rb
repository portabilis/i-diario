require 'rails_helper'
require Rails.root.join(
  'db', 'migrate',
  '20260608130000_grant_copy_teaching_plan_permissions_to_teacher_roles.rb'
)

RSpec.describe GrantCopyTeachingPlanPermissionsToTeacherRoles do
  subject(:migration) { described_class.new }

  let(:copy_features) { %w[copy_discipline_teaching_plan copy_knowledge_area_teaching_plan] }

  def permission_for(role, feature)
    role.permissions.find_by(feature: feature)&.permission
  end

  describe '#up' do
    context 'when the teacher role has no copy permission rows' do
      let!(:teacher_role) { create(:role, :teacher) }

      it 'grants both copy features as CHANGE' do
        migration.up
        teacher_role.reload

        copy_features.each do |feature|
          expect(permission_for(teacher_role, feature)).to eq(Permissions::CHANGE)
        end
      end
    end

    context 'when the teacher role already has the rows as DENIED' do
      let!(:teacher_role) { create(:role, :teacher) }

      before do
        copy_features.each do |feature|
          create(:role_permission, role: teacher_role, feature: feature, permission: Permissions::DENIED)
        end
      end

      it 'upgrades DENIED to CHANGE without duplicating' do
        migration.up
        teacher_role.reload

        copy_features.each do |feature|
          expect(teacher_role.permissions.where(feature: feature).count).to eq(1)
          expect(permission_for(teacher_role, feature)).to eq(Permissions::CHANGE)
        end
      end
    end

    context 'when run twice' do
      let!(:teacher_role) { create(:role, :teacher) }

      it 'is idempotent (single CHANGE row per feature)' do
        migration.up
        migration.up
        teacher_role.reload

        copy_features.each do |feature|
          expect(teacher_role.permissions.where(feature: feature).count).to eq(1)
          expect(permission_for(teacher_role, feature)).to eq(Permissions::CHANGE)
        end
      end
    end

    context 'when the role is not a teacher' do
      let!(:admin_role) { create(:role, :administrator) }

      it 'does not grant the copy features to non-teacher roles' do
        migration.up
        admin_role.reload

        copy_features.each do |feature|
          expect(admin_role.permissions.where(feature: feature)).to be_empty
        end
      end
    end
  end

  describe '#down' do
    let!(:teacher_role) { create(:role, :teacher) }

    it 'reverts the copy features back to DENIED' do
      migration.up
      migration.down
      teacher_role.reload

      copy_features.each do |feature|
        expect(permission_for(teacher_role, feature)).to eq(Permissions::DENIED)
      end
    end
  end
end
