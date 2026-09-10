class CollegesController < ApplicationController
  require_role :owner, :manager

  def index
    @colleges = College.order(:name)
  end

  def new
    @college = College.new
    @college.build_address
  end

  def create
    @college = College.new(college_params)
    @college.is_active = true

    if @college.save
      redirect_to colleges_path, notice: "Faculdade cadastrada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def college_params
      params.require(:college).permit(
        :name,
        address_attributes: %i[street number complement neighborhood country zip_code]
      )
    end
end
