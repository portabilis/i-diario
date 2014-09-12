# encoding: utf-8
require 'rails_helper'

RSpec.describe IeducarApiConfiguration, :type => :model do
  context "Associations" do
    it { should have_many :syncronizations }
  end

  context "Validations" do
    it { should validate_presence_of :url }
    it { should validate_presence_of :token }
    it { should validate_presence_of :secret_token }
    it { should validate_presence_of :unity_code }

    it { should allow_value('http://ieducar.com.br', 'https://ieducar.com', 'https://10.0.0.1').for(:url) }
    it { should_not allow_value('ftp://ieducar.com').for(:url).
      with_message("formato de url inválido") }
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

  describe "#start_syncronization!" do
    it "starts a syncronization with a given user" do
      user = double
      syncronizations = double

      expect(subject).to receive(:syncronizations).and_return(syncronizations)
      expect(syncronizations).to receive(:create!).with(
        status: ApiSyncronizationStatus::STARTED,
        author: user
      )

      subject.start_syncronization!(user)
    end
  end

  describe "#to_api" do
    it "returns config to be used in the api" do
      url = "http://teste.com.br"
      token = "123abc"
      secret_token = "abc123"
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
