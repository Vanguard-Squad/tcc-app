# Análise dos contratos assinados que os alunos enviam.
class ContractsController < ApplicationController
  require_role :owner, :manager

  STATUS_FILTERS = { "em-analise" => "under_review", "aguardando" => "pending", "recusados" => "rejected", "aprovados" => "approved" }.freeze

  before_action :set_contract, except: :index

  def index
    contracts = Contract.for_company(current_company)
    @counts = contracts.group(:status).count
    @filter = params[:situacao].presence_in(STATUS_FILTERS.keys) || "em-analise"
    @contracts = contracts.where(status: STATUS_FILTERS[@filter])
      .includes(student: [ :user, :college ]).order(submitted_at: :desc, created_at: :desc)
  end

  def show
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
