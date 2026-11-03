# Contrato de transporte do aluno. O aluno baixa o PDF gerado pelo sistema,
# assina pelo gov.br e anexa o arquivo assinado; a secretaria confere a
# assinatura e aprova. Só com o contrato aprovado o aluno usa o sistema.
class Contract < ApplicationRecord
  MAX_FILE_SIZE = 10.megabytes

  belongs_to :student
  belongs_to :reviewed_by, class_name: "User", optional: true
  has_one_attached :signed_file

  enum :status, { pending: "pending", under_review: "under_review", approved: "approved", rejected: "rejected" }

  STATUS_LABELS = {
    "pending" => "Aguardando assinatura", "under_review" => "Em análise",
    "approved" => "Aprovado", "rejected" => "Recusado"
  }.freeze

  validates :rejection_reason, presence: true, if: :rejected?
  validate :signed_file_is_a_pdf

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

  private
    def signed_file_is_a_pdf
      return unless signed_file.attached? && attachment_changes["signed_file"]

      errors.add(:base, "O contrato assinado precisa ser um arquivo PDF") unless signed_file.content_type == "application/pdf"
      errors.add(:base, "O contrato assinado precisa ter no máximo 10 MB") if signed_file.byte_size > MAX_FILE_SIZE
    end
end
