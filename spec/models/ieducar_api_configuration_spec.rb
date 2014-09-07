# encoding: utf-8
require 'rails_helper'

RSpec.describe IeducarApiConfiguration, :type => :model do
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
end
