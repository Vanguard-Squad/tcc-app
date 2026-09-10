module ApplicationHelper
  ROLE_LABELS = {
    "owner" => "Dono(a)",
    "manager" => "Secretaria",
    "student" => "Aluno(a)",
    "driver" => "Motorista"
  }.freeze

  def role_label(role)
    ROLE_LABELS.fetch(role.to_s, role.to_s)
  end
end
