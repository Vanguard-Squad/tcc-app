class AuditLogsController < ApplicationController
  require_role :owner

  PER_PAGE = 50

  def index
    @users = current_company.employees.order(:name)
    logs = Log.where(company: current_company).includes(:user, :auditable)
    logs = logs.where(user_id: params[:user_id]) if params[:user_id].present?
    logs = logs.where("action LIKE ?", "#{Log.sanitize_sql_like(params[:category])}.%") if params[:category].present?
    logs = logs.where(created_at: parse_date(params[:from]).beginning_of_day..) if parse_date(params[:from])
    logs = logs.where(created_at: ..parse_date(params[:to]).end_of_day) if parse_date(params[:to])

    @page = [ params[:page].to_i, 1 ].max
    @logs = logs.recent_first.offset((@page - 1) * PER_PAGE).limit(PER_PAGE + 1).to_a
    @next_page = @logs.size > PER_PAGE
    @logs = @logs.first(PER_PAGE)
  end

  private
    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end
end
