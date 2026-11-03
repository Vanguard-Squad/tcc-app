# Análise dos contratos assinados que os alunos enviam.
class ContractsController < ApplicationController
  require_role :owner, :manager

  STATUS_FILTERS = { "em-analise" => "under_review", "aguardando" => "pending", "recusados" => "rejected", "aprovados" => "approved" }.freeze

  before_action :set_contract, except: %i[index template update_template]

  def index
    @template = current_company.contract_template
    contracts = Contract.for_company(current_company)
    @counts = contracts.group(:status).count
    @filter = params[:situacao].presence_in(STATUS_FILTERS.keys) || "em-analise"
    @contracts = contracts.where(status: STATUS_FILTERS[@filter])
      .includes(student: [ :user, :college ]).order(submitted_at: :desc, created_at: :desc)
  end

  def show
  end

  # Modelo de contrato da empresa, que os alunos baixam para assinar.
  def template
    template = current_company.contract_template
    return redirect_to(contracts_path, alert: "Nenhum modelo de contrato anexado.") unless template.attached?

    send_data template.download, filename: template.filename.to_s, type: "application/pdf", disposition: "inline"
  end

  def update_template
    file = params[:contract_template]
    return redirect_to(contracts_path, alert: "Selecione o PDF do contrato.") if file.blank?

    if current_company.update(contract_template: file)
      audit("contract.template_uploaded", current_company, arquivo: current_company.contract_template.filename.to_s)
      redirect_to contracts_path, notice: "Modelo de contrato atualizado. Os alunos já baixam esta versão."
    else
      redirect_to contracts_path, alert: current_company.errors.full_messages.to_sentence
    end
  end

  def file
    return redirect_to(contract_path(@contract), alert: "O aluno ainda não enviou o contrato assinado.") unless @contract.signed_file.attached?

    send_data @contract.signed_file.download, filename: @contract.signed_file.filename.to_s,
      type: "application/pdf", disposition: params[:baixar] ? "attachment" : "inline"
  end

  def approve
    return redirect_to(contract_path(@contract), alert: "Só é possível aprovar contratos em análise.") unless @contract.under_review?

    @contract.approve!(current_user)
    audit("contract.approved", @contract)
    redirect_to contracts_path, notice: "Contrato de #{@contract.student.user.name} aprovado. O aluno já pode usar o sistema."
  end

  def reject
    return redirect_to(contract_path(@contract), alert: "Só é possível recusar contratos em análise.") unless @contract.under_review?

    @contract.reject!(current_user, params[:rejection_reason].to_s.strip)
    audit("contract.rejected", @contract, motivo: @contract.rejection_reason)
    redirect_to contracts_path, notice: "Contrato de #{@contract.student.user.name} recusado. O aluno vai ver o motivo e poderá reenviar."
  rescue ActiveRecord::RecordInvalid
    @contract.restore_attributes
    flash.now[:alert] = "Informe o motivo da recusa para o aluno saber o que corrigir."
    render :show, status: :unprocessable_entity
  end

  private
    def set_contract
      @contract = Contract.for_company(current_company).find(params[:id])
    end
end
