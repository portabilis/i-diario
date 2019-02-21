# encoding: utf-8
require 'rails_helper'

RSpec.describe IeducarApiConfiguration, :type => :model do
  context "Associations" do
    it { should have_many :synchronizations }
  end

  context "Validations" do
    it { should validate_presence_of :url }
    it { should validate_presence_of :unity_code }

    it { should allow_value('http://ieducar.com.br', 'https://ieducar.com', 'https://10.0.0.1').for(:url) }
    it { should_not allow_value('ftp://ieducar.com').for(:url).
      with_message("formato de url inválido") }

    context 'on production' do
      before do
        Rails.stub_chain(:env, production?: true)
      end

      it { should validate_presence_of :token }
      it { should validate_presence_of :secret_token }
    end
  end

  describe ".current" do
    before(:all) do
      # At this point the fixtures where loaded
      IeducarApiConfiguration.destroy_all
    end

    context "when config wasn't made" do
      it "builds a new config" do
        expect(IeducarApiConfiguration.current).to be_new_record
      end
    end

    context "when there is a previous config" do
      it "returns existent config" do
        subject = IeducarApiConfiguration.create!(
          url: "http://ieducar.com",
          token: "asd",
          secret_token: "123asd",
          unity_code: "123"
        )

        expect(IeducarApiConfiguration.current).to eq subject
      end
    end
  end

  describe "#start_synchronization" do
    it "starts a synchronization with a given user" do
      expect(IeducarSynchronizerWorker).
        to receive(:perform_in).
        and_return(rand(999))

      user = create(:user)
      subject = create(:ieducar_api_configuration)

      sync = subject.start_synchronization(user, 1)

      expect(sync.status).to eq ApiSynchronizationStatus::STARTED
      expect(sync.author).to eq user
      expect(sync.job_id).to_not be_nil
      expect(sync.worker_batch).to be_present
    end
  end

  describe "#to_api" do
    it "returns config to be used in the api" do
      url = "http://teste.com.br"
      token = "8IOwGIjiHvbeTklgwo10yVLgwDhhvs"
      secret_token = "5y8cfq31oGvFdAlGMCLIeSKdfc8pUC"
      unity_code = "123"

      subject.url = url
      subject.token = token
      subject.secret_token = secret_token
      subject.unity_code = unity_code

      expect(subject.to_api).to eq({
        url: url,
        access_key: token,
        secret_key: secret_token,
        unity_id: unity_code
      })
    end
  end
end
