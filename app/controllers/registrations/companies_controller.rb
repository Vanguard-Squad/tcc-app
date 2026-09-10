module Registrations
  class CompaniesController < ApplicationController
    allow_incomplete_registration only: %i[new create]
    before_action :redirect_if_registration_complete

    def new
      @company = current_user.build_owned_company
      @company.build_address
    end

    def create
      @company = current_user.build_owned_company(company_params)

      if @company.save
        redirect_to root_path, notice: "Cadastro concluído! Bem-vindo(a), #{current_user.name}."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private
      def company_params
        params.require(:company).permit(
          :name, :cnpj,
          address_attributes: %i[street number complement neighborhood country zip_code]
        )
      end

      def redirect_if_registration_complete
        redirect_to root_path, notice: "Sua empresa já está cadastrada." if current_user.registration_complete?
      end
  end
end
