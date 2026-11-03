module ContractsHelper
  GOV_BR_SIGNER_URL = "https://assinador.iti.br".freeze

  STATUS_BADGES = {
    "pending" => "status-waiting", "under_review" => "status-boarded",
    "approved" => "status-active", "rejected" => "status-inactive"
  }.freeze

  def contract_status_badge(contract)
    tag.span(contract.status_label, class: [ "status-badge", STATUS_BADGES.fetch(contract.status) ])
  end
end
