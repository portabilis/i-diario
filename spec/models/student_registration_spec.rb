# encoding: utf-8
require 'rails_helper'

RSpec.describe StudentRegistration, :type => :model do
  let :attributes do
    {
      "aluno_nome" => "Ivanilson Bitencourt Gabriel",
      "ano" => "2013",
      "curso_nome" => "Ensino Fundamental - 8 Anos (Séries Finais)",
      "escola_nome" => "Emef Paulo Rizzieri",
      "id" => "19226",
      "serie_nome" => "8ª série",
      "turma_nome" => "8ª série 90-m"
    }
  end

  subject do
    StudentRegistration.new(attributes)
  end

  it "returns newsletter id" do
    expect(subject.id).to eq attributes["id"]
  end

  it "returns school id" do
    expect(subject.school_id).to eq attributes["school_id"]
  end

  it "returns student name" do
    expect(subject.student).to eq attributes["aluno_nome"]
  end

  it "returns year" do
    expect(subject.year).to eq attributes["ano"]
  end

  it "returns classroom" do
    expect(subject.classroom).to eq attributes["turma_nome"]
  end

  it "returns series" do
    expect(subject.series).to eq attributes["serie_nome"]
  end

  it "returns course" do
    expect(subject.course).to eq attributes["curso_nome"]
  end

  it "returns school" do
    expect(subject.school).to eq attributes["escola_nome"]
  end
end
