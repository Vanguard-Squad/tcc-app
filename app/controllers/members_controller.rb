class MembersController < ApplicationController
  require_role :owner, :manager

  ROLE_FILTERS = { "alunos" => "student", "motoristas" => "driver", "secretaria" => "manager" }.freeze
  # Pendências apontadas no painel "Precisa de atenção" do início.
  ISSUES = { "sem-onibus" => "Alunos sem ônibus", "sem-localizacao" => "Alunos com endereço sem localização no mapa" }.freeze

  def index
    members = current_company.employees.includes(:driver, student: :college).order(:name)
    @counts = current_company.employees.group(:role).count
    @total = @counts.values.sum
    @filter = params[:papel].presence_in(ROLE_FILTERS.keys)
    members = members.where(role: ROLE_FILTERS[@filter]) if @filter
    @issue = params[:pendencia].presence_in(ISSUES.keys)
    members = with_issue(members, @issue) if @issue
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

  private
    def with_issue(members, issue)
      students = Student.joins(:user).where(users: { company_id: current_company.id, is_active: true })
      students = case issue
      when "sem-onibus" then students.where.missing(:vehicle_students)
      when "sem-localizacao" then students.joins(:address).where(addresses: { latitude: nil }).or(students.joins(:address).where(addresses: { longitude: nil }))
      end
      members.where(id: students.select(:user_id))
    end
end
