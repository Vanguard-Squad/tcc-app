module Students
  # Primeiro acesso do aluno: baixar o contrato, assinar pelo gov.br e anexar
  # o PDF assinado. O resto do sistema fica bloqueado até a aprovação.
  class ContractsController < ApplicationController
    require_role :student
    allow_pending_contract

    before_action :set_contract

    def show
    end

    def download
      template = current_company.contract_template
      return redirect_to(students_contract_path, alert: "A empresa ainda não disponibilizou o contrato.") unless template.attached?

      audit("contract.downloaded", @contract)
      send_data template.download, filename: template.filename.to_s, type: "application/pdf", disposition: "attachment"
    end

    def update
      return redirect_to(students_contract_path, alert: "Seu contrato já foi enviado.") unless @contract.awaiting_upload?

      file = params.dig(:contract, :signed_file)
      return redirect_to(students_contract_path, alert: "Selecione o PDF do contrato assinado.") if file.blank?

      @contract.submit!(file)
      audit("contract.submitted", @contract)
      redirect_to students_contract_path, notice: "Contrato enviado! Agora é só aguardar a análise da secretaria."
    rescue ActiveRecord::RecordInvalid
      flash.now[:alert] = @contract.errors.full_messages.to_sentence
      @contract.restore_attributes
      render :show, status: :unprocessable_entity
    end

    private
      def set_contract
        student = current_user.student
        return redirect_to(root_path, alert: "Perfil de aluno não encontrado.") unless student

        @contract = student.current_contract
      end
  end
end
