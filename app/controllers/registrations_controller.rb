class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  before_action :redirect_if_already_signed_in

  def new
    @user = User.new
  end

  def create
    @user = User.new(account_params)
    @user.is_active = true

    if @user.save
      start_new_session_for(@user)
      redirect_to new_registration_company_path, notice: "Conta criada! Agora cadastre sua empresa."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def account_params
      params.require(:user).permit(:name, :username, :password, :password_confirmation)
    end

    def redirect_if_already_signed_in
      return unless current_user

      redirect_to current_user.registration_complete? ? root_path : new_registration_company_path
    end
end
