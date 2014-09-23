# encoding: utf-8
require 'rails_helper'

RSpec.describe DisciplinaryIncident, :type => :model do
  let :attributes do
    {
      "aluno_id" => "123",
      "tipo" => "tipo ocorrência",
      "data_hora" => "10/10/2014 10:10",
      "descricao" => "descricao ocorrência"
    }
  end

  subject do
    DisciplinaryIncident.new(attributes)
  end

  it "finds a student using aluno_id" do
    expect(Student).to receive(:find_by).with(api_code: "123")

    subject.student
  end

  it "returns date" do
    expect(subject.date).to eq "10/10/2014 10:10"
  end

  it "returns kind" do
    expect(subject.kind).to eq "tipo ocorrência"
  end

  it "returns description" do
    expect(subject.description).to eq "descricao ocorrência"
  end
end
