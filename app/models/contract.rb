# Contrato de transporte do aluno. O aluno baixa o modelo anexado pela
# secretaria da empresa, assina pelo gov.br e anexa o arquivo assinado; a secretaria confere a
# assinatura e aprova. Só com o contrato aprovado o aluno usa o sistema.
class Contract < ApplicationRecord
  belongs_to :student
  belongs_to :reviewed_by, class_name: "User", optional: true
  has_one_attached :signed_file

  enum :status, { pending: "pending", under_review: "under_review", approved: "approved", rejected: "rejected" }

  STATUS_LABELS = {
    "pending" => "Aguardando assinatura", "under_review" => "Em análise",
    "approved" => "Aprovado", "rejected" => "Recusado"
  }.freeze

  validates :rejection_reason, presence: true, if: :rejected?
  validates :signed_file, pdf_attachment: { label: "O contrato assinado" }

  scope :for_company, ->(company) { joins(student: :user).where(users: { company_id: company.id }) }

  def status_label
    STATUS_LABELS.fetch(status)
  end

  # Aluno ainda pode (re)enviar o arquivo: antes do primeiro envio ou depois de recusado.
  def awaiting_upload?
    pending? || rejected?
  end

  def submit!(file)
    signed_file.attach(file)
    update!(status: :under_review, submitted_at: Time.current, rejection_reason: nil, reviewed_at: nil, reviewed_by: nil)
  end

  def approve!(reviewer)
    update!(status: :approved, reviewed_at: Time.current, reviewed_by: reviewer, rejection_reason: nil)
  end

  def reject!(reviewer, reason)
    update!(status: :rejected, reviewed_at: Time.current, reviewed_by: reviewer, rejection_reason: reason)
  end
end
