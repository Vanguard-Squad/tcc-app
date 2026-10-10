module AuditLogsHelper
  CATEGORY_LABELS = {
    "session" => "Acesso",
    "member" => "Membros",
    "vehicle" => "Frota",
    "route" => "Rotas",
    "trip" => "Viagens",
    "checkin" => "Check-ins"
  }.freeze

  def audit_target_label(log)
    record = log.auditable
    return "—" if record.nil?

    case record
    when User then "#{record.name} (#{role_label(record.role)})"
    when Vehicle then "Ônibus #{record.license_plate}"
    when Route then "Rota #{record.name}"
    when Trip then "Viagem #{record.outbound? ? 'de ida' : 'de volta'} — #{record.vehicle.license_plate}"
    when Company then record.name
    else "#{record.class.model_name.human} ##{record.id}"
    end
  end

  def audit_details(log)
    log.details.map do |key, value|
      value = "#{value.first.presence || '—'} → #{value.last.presence || '—'}" if value.is_a?(Array) && value.size == 2
      "#{key}: #{value}"
    end
  end
end
