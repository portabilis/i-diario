require 'rails_helper'

RSpec.describe RegistrationTeacherLinkerService, type: :service do
  let(:service) { described_class.new }
  let!(:api_config) { create(:ieducar_api_configuration) }

  describe '#call' do
    context 'when user is nil' do
      it 'returns early without processing' do
        expect(service).not_to receive(:fetch_teacher_from_api)
        service.call(nil)
      end
    end

    context 'when user has no CPF' do
      let(:user) { create(:user, cpf: nil, teacher_id: nil) }

      it 'returns early without processing' do
        expect(service).not_to receive(:fetch_teacher_from_api)
        service.call(user)
      end
    end

    context 'when user has blank CPF' do
      let(:user) { create(:user, cpf: '', teacher_id: nil) }

      it 'returns early without processing' do
        expect(service).not_to receive(:fetch_teacher_from_api)
        service.call(user)
      end
    end

    context 'when user has valid CPF' do
      let(:user) { create(:user, cpf: '123.456.789-01', teacher_id: nil) }

      context 'when API configuration is missing' do
        before do
          IeducarApiConfiguration.destroy_all
        end

        it 'returns early without processing' do
          expect(service).not_to receive(:find_or_create_teacher)
          service.call(user)
        end

        it 'does not link user to teacher' do
          expect { service.call(user) }.not_to change { user.reload.teacher_id }
        end
      end

      context 'when API returns no data' do
        before do
          allow_any_instance_of(IeducarApi::Teachers).to receive(:fetch_by_cpf).and_return({})
        end

        it 'returns early without creating teacher' do
          expect(service).not_to receive(:find_or_create_teacher)
          service.call(user)
        end

        it 'does not link user to teacher' do
          expect { service.call(user) }.not_to change { user.reload.teacher_id }
        end
      end

      context 'when API returns valid teacher data' do
        let(:teacher_data) do
          {
            'result' => {
              'servidor_id' => '100',
              'nome' => 'João Professor',
              'cpf' => '123.456.789-01',
              'ativo' => 1
            }
          }
        end

        before do
          allow_any_instance_of(IeducarApi::Teachers).to receive(:fetch_by_cpf).and_return(teacher_data)
        end

        context 'when teacher does not exist' do
          it 'creates new teacher' do
            expect { service.call(user) }.to change { Teacher.count }.by(1)

            teacher = Teacher.find_by(api_code: '100')
            expect(teacher.name).to eq('João Professor')
            expect(teacher.active).to be true
          end
        end

        context 'when teacher already exists' do
          let!(:existing_teacher) { create(:teacher, api_code: '100', name: 'João Antigo') }

          it 'updates existing teacher' do
            expect { service.call(user) }.not_to change { Teacher.count }

            existing_teacher.reload
            expect(existing_teacher.name).to eq('João Professor')
            expect(existing_teacher.active).to be true
          end
        end

        context 'when teacher is not an active professor' do
          let!(:teacher) { create(:teacher, api_code: '100', active: true) }

          before do
            expect(teacher.teacher_discipline_classrooms).to be_empty
          end

          it 'does not link user to teacher' do
            expect { service.call(user) }.not_to change { user.reload.teacher_id }
          end

          it 'logs reason for not linking' do
            allow(Rails.logger).to receive(:info)
            expect(Rails.logger).to receive(:info).with(
              "Teacher #{teacher.id} (João Professor) não possui vínculo com turmas."
            )
            service.call(user)
          end
        end

        context 'when teacher is an active professor' do
          let!(:teacher) { create(:teacher, api_code: '100', active: true) }
          let!(:classroom) { create(:classroom) }
          let!(:discipline) { create(:discipline) }
          let!(:teacher_discipline_classroom) do
            create(:teacher_discipline_classroom,
                   teacher: teacher,
                   classroom: classroom,
                   discipline: discipline)
          end

          it 'links user to teacher' do
            service.call(user)
            expect(user.reload.teacher_id).to eq(teacher.id)
          end

          it 'logs successful linking' do
            allow(Rails.logger).to receive(:info)
            expect(Rails.logger).to receive(:info).with(
              "Usuário #{user.id} (#{user.name}) vinculado ao professor #{teacher.id} durante o registro"
            )
            service.call(user)
          end

          context 'when user is already linked to the teacher' do
            before { user.update!(teacher_id: teacher.id) }

            it 'does not attempt to link again' do
              expect(user).not_to receive(:save)
              service.call(user)
            end
          end

          context 'when user save fails' do
            before do
              allow(user).to receive(:save).with(validate: false).and_return(false)
              allow(user).to receive(:errors).and_return(
                double(full_messages: ['Custom validation error'])
              )
            end

            it 'logs the error' do
              allow(Rails.logger).to receive(:info)
              expect(Rails.logger).to receive(:warn).with(
                "Falha ao vincular usuário #{user.id} ao professor #{teacher.id}: Custom validation error"
              )
              service.call(user)
            end

            it 'does not link the user' do
              expect { service.call(user) }.not_to change { user.reload.teacher_id }
            end
          end
        end

        context 'when teacher data has no servidor_id' do
          let(:invalid_teacher_data) do
            {
              'result' => {
                'servidor_id' => nil,
                'nome' => 'João Professor',
                'cpf' => '123.456.789-01',
                'ativo' => 1
              }
            }
          end

          before do
            allow_any_instance_of(IeducarApi::Teachers).to receive(:fetch_by_cpf).and_return(invalid_teacher_data)
          end

          it 'does not create teacher' do
            expect { service.call(user) }.not_to change { Teacher.count }
          end

          it 'does not link user' do
            expect { service.call(user) }.not_to change { user.reload.teacher_id }
          end
        end

        context 'when teacher save fails' do
          before do
            allow_any_instance_of(Teacher).to receive(:save).and_return(false)
            allow_any_instance_of(Teacher).to receive(:errors).and_return(
              double(full_messages: ['Teacher validation error'])
            )
          end

          it 'logs the error' do
            allow(Rails.logger).to receive(:warn)
            expect(Rails.logger).to receive(:warn).with(
              'Falha ao salvar professor: Teacher validation error'
            )
            service.call(user)
          end

          it 'does not link user' do
            expect { service.call(user) }.not_to change { user.reload.teacher_id }
          end
        end

        context 'when teacher is inactive in API' do
          let(:inactive_teacher_data) do
            {
              'result' => {
                'servidor_id' => '100',
                'nome' => 'João Professor',
                'cpf' => '123.456.789-01',
                'ativo' => 0
              }
            }
          end

          before do
            allow_any_instance_of(IeducarApi::Teachers).to receive(:fetch_by_cpf).and_return(inactive_teacher_data)
          end

          it 'creates teacher as inactive' do
            service.call(user)
            teacher = Teacher.find_by(api_code: '100')
            expect(teacher.active).to be false
          end

          it 'does not link user (teacher not active)' do
            expect { service.call(user) }.not_to change { user.reload.teacher_id }
          end
        end
      end

      context 'when API raises an error' do
        before do
          allow_any_instance_of(IeducarApi::Teachers).to receive(:fetch_by_cpf).and_raise(StandardError, 'API Error')
        end

        it 'logs the error' do
          allow(Rails.logger).to receive(:warn)
          expect(Rails.logger).to receive(:warn).with(
            'Erro ao buscar servidor na API do iEducar para CPF 123.456.789-01: API Error'
          )
          service.call(user)
        end

        it 'does not link user' do
          expect { service.call(user) }.not_to change { user.reload.teacher_id }
        end

        it 'does not create teacher' do
          expect { service.call(user) }.not_to change { Teacher.count }
        end
      end
    end
  end

  describe '#active_with_teacher_discipline_classrooms?' do
    context 'when teacher is active and has discipline classrooms' do
      let(:teacher) { create(:teacher, active: true) }
      let(:classroom) { create(:classroom) }
      let(:discipline) { create(:discipline) }

      before do
        create(:teacher_discipline_classroom,
               teacher: teacher,
               classroom: classroom,
               discipline: discipline)
      end

      it 'returns true' do
        expect(service.send(:active_with_teacher_discipline_classrooms?, teacher)).to be true
      end
    end

    context 'when teacher is active but has no discipline classrooms' do
      let(:teacher) { create(:teacher, active: true) }

      it 'returns false' do
        expect(service.send(:active_with_teacher_discipline_classrooms?, teacher)).to be false
      end
    end

    context 'when teacher is inactive but has discipline classrooms' do
      let(:teacher) { create(:teacher, active: false) }
      let(:classroom) { create(:classroom) }
      let(:discipline) { create(:discipline) }

      before do
        create(:teacher_discipline_classroom,
               teacher: teacher,
               classroom: classroom,
               discipline: discipline)
      end

      it 'returns false' do
        expect(service.send(:active_with_teacher_discipline_classrooms?, teacher)).to be false
      end
    end

    context 'when teacher is inactive and has no discipline classrooms' do
      let(:teacher) { create(:teacher, active: false) }

      it 'returns false' do
        expect(service.send(:active_with_teacher_discipline_classrooms?, teacher)).to be false
      end
    end
  end
end
