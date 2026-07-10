require 'rails_helper'

RSpec.describe IepAttachment, type: :model do
  let(:plan) { create(:individualized_educational_plan) }

  def upload(name)
    File.open(Rails.root.join('spec', 'fixtures', 'files', name))
  end

  describe 'attachment extension whitelist' do
    it 'is valid with an allowed extension' do
      attachment = build(:iep_attachment, iep: plan, attachment: upload('laudo.pdf'))

      expect(attachment).to be_valid
    end

    it 'is invalid with a disallowed extension' do
      attachment = build(:iep_attachment, iep: plan, attachment: upload('malware.exe'))

      expect(attachment).not_to be_valid
      expect(attachment.errors[:attachment]).to be_present
    end
  end

  describe 'set_attachment_attributes' do
    it 'stores file name, content type and size on save' do
      attachment = create(:iep_attachment, iep: plan, attachment: upload('laudo.pdf'))

      expect(attachment.attachment_file_name).to eq('laudo.pdf')
      expect(attachment.attachment_content_type).to be_present
      expect(attachment.attachment_file_size).to match(/ kB\z/)
    end
  end
end
