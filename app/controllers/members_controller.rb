class MembersController < ApplicationController
  require_role :owner, :manager

  ROLE_FILTERS = { "alunos" => "student", "motoristas" => "driver", "secretaria" => "manager" }.freeze

  def index
    members = current_company.employees.includes(:driver, student: :college).order(:name)
    @counts = current_company.employees.group(:role).count
    @total = @counts.values.sum
    @filter = params[:papel].presence_in(ROLE_FILTERS.keys)
    members = members.where(role: ROLE_FILTERS[@filter]) if @filter
    members = members.where("users.name ILIKE :q OR users.email ILIKE :q", q: "%#{User.sanitize_sql_like(params[:q])}%") if params[:q].present?
    @members = members
  end

  def toggle_active
    member = current_company.employees.where(role: current_user.manageable_roles).find(params[:id])
    member.update!(is_active: !member.is_active?)

    if member.is_active?
      audit("member.activated", member)
      redirect_to members_path, notice: "#{member.name} foi reativado(a)."
    else
      audit("member.deactivated", member)
      redirect_to members_path, notice: "#{member.name} foi desativado(a) e não consegue mais entrar no sistema."
    end
  end
end
