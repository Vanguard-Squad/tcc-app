class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
  end

  def create
    user = User.find_by(username: params[:username].to_s.strip.downcase)

    if user&.authenticate(params[:password]) && user.is_active?
      start_new_session_for(user)
      redirect_to after_login_path(user), notice: "Login realizado com sucesso."
    else
      flash.now[:alert] = "Usuário ou senha inválidos."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to login_path, notice: "Você saiu da sua conta."
  end

  private
    def after_login_path(user)
      user.registration_complete? ? root_path : new_registration_company_path
    end
end
