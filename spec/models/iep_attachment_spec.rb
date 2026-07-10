require 'rails_helper'

RSpec.describe IepAttachment, type: :model do
  let(:plan) { create(:individualized_educational_plan) }

  describe 'medical report immutability in a published version' do
    it 'prevents removing a report referenced in a version snapshot' do
      attachment = create(:iep_attachment, iep: plan)
      attachment.update_column(:attachment_file_name, 'laudo.pdf')
      create(
        :iep_version, :current,
        iep: plan,
        content: { 'attachments' => [{ 'file_name' => 'laudo.pdf' }] }
      )

      expect(attachment.destroy).to eq(false)
      expect(described_class.exists?(attachment.id)).to eq(true)
    end

    it 'allows removing a report in a draft (no versions)' do
      attachment = create(:iep_attachment, iep: plan)
      attachment.update_column(:attachment_file_name, 'laudo.pdf')

      expect(attachment.destroy).to be_truthy
      expect(described_class.exists?(attachment.id)).to eq(false)
    end

    it 'does not block when the report is not cited in any version' do
      attachment = create(:iep_attachment, iep: plan)
      attachment.update_column(:attachment_file_name, 'outro.pdf')
      create(
        :iep_version, :current,
        iep: plan,
        content: { 'attachments' => [{ 'file_name' => 'laudo.pdf' }] }
      )

      expect(attachment.destroy).to be_truthy
    end
  end
end
