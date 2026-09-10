class MembersController < ApplicationController
  require_role :owner, :manager

  def index
    @members = current_company.employees.includes(:student, :driver).order(:name)
  end
end
