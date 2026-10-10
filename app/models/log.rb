# Registro de auditoria: quem fez o quê, em qual registro e quando.
class Log < ApplicationRecord
  ACTION_LABELS = {
    "session.login" => "Entrou no sistema",
    "session.login_failed" => "Tentativa de login com senha errada",
    "session.logout" => "Saiu do sistema",
    "company.created" => "Cadastrou a empresa",
    "member.created" => "Cadastrou membro",
    "member.updated" => "Editou membro",
    "member.activated" => "Reativou membro",
    "member.deactivated" => "Desativou membro",
    "vehicle.created" => "Cadastrou ônibus",
    "vehicle.updated" => "Editou ônibus",
    "route.created" => "Cadastrou rota",
    "route.updated" => "Editou rota",
    "route.stops_reordered" => "Reordenou paradas",
    "trip.started" => "Iniciou viagem",
    "trip.finished" => "Finalizou viagem",
    "checkin.registered" => "Registrou check-in",
    "checkin.qr_registered" => "Registrou check-in por QR code"
  }.freeze

  IGNORED_CHANGES = %w[created_at updated_at password_digest latitude longitude].freeze

  belongs_to :user
  belongs_to :company, optional: true
  belongs_to :auditable, polymorphic: true, optional: true

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  def self.record!(user:, action:, auditable: nil, details: {}, ip_address: nil)
    create!(user: user, company_id: user.company_id, action: action, auditable: auditable,
      details: details.compact_blank, ip_address: ip_address)
  end

  # Alterações salvas de um ou mais registros, no formato { "campo" => [antes, depois] },
  # sem campos internos.
  def self.changes_of(*records)
    records.compact.reduce({}) { |all, record| all.merge(record.saved_changes.except(*IGNORED_CHANGES)) }
  end

  def action_label
    ACTION_LABELS.fetch(action, action)
  end
end
