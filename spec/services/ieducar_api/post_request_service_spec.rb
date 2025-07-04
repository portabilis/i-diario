require 'spec_helper'

RSpec.describe IeducarApi::PostRequestService, type: :service do
  let(:posting) { instance_double('IeducarApiExamPosting') }
  let(:params) { { notas: { '1' => { '1' => { '1' => { nota: 8.5 } } } } } }
  let(:info) { { 'classroom' => '1', 'student' => '1', 'discipline' => '1' } }
  let(:api_client) { instance_double('IeducarApi::PostExams') }
  let(:response) { { 'any_error_msg' => false } }

  subject { described_class.new(posting) }

  before do
    allow(posting).to receive(:post_type).and_return(ApiPostingTypes::NUMERICAL_EXAM)
    allow(posting).to receive(:to_api).and_return({})
    allow(IeducarApi::PostExams).to receive(:new).and_return(api_client)
    allow(IeducarApi::InfoMessageBuilder).to receive(:new).with(info).and_return(
      instance_double('IeducarApi::InfoMessageBuilder', build: 'Turma: Turma 1;<br>')
    )
  end

  describe '#execute' do
    context 'quando a requisição é bem-sucedida' do
      before do
        allow(api_client).to receive(:send_post).with(params.with_indifferent_access).and_return(response)
        allow(IeducarResponseDecorator).to receive(:new).with(response).and_return(
          instance_double('IeducarResponseDecorator', any_error_message?: false)
        )
      end

      it 'executa a requisição sem erros' do
        expect { subject.execute(params, info) }.not_to raise_error
      end
    end

    context 'quando há mensagens de warning na resposta' do
      let(:response_decorator) { instance_double('IeducarResponseDecorator') }

      before do
        allow(api_client).to receive(:send_post).and_return(response)
        allow(IeducarResponseDecorator).to receive(:new).and_return(response_decorator)
        allow(response_decorator).to receive(:any_error_message?).and_return(true)
        allow(response_decorator).to receive(:full_error_message).and_return('Warning message')
        allow(posting).to receive(:add_warning!)
      end

      it 'adiciona warning ao posting' do
        subject.execute(params, info)
        expect(posting).to have_received(:add_warning!).with('Warning message')
      end
    end

    context 'quando ocorre um erro' do
      let(:error) { StandardError.new('Erro de teste') }
      let(:error_handler) { instance_double('IeducarApi::ErrorHandlerService') }

      before do
        allow(api_client).to receive(:send_post).and_raise(error)
        allow(IeducarApi::ErrorHandlerService).to receive(:new).with(posting).and_return(error_handler)
        allow(error_handler).to receive(:handle).with(error, 'Turma: Turma 1;<br>')
      end

      it 'delega o tratamento do erro para ErrorHandlerService' do
        subject.execute(params, info)
        expect(error_handler).to have_received(:handle).with(error, 'Turma: Turma 1;<br>')
      end
    end
  end
end
