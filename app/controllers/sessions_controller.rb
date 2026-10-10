class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)

    if user&.authenticate(params[:password]) && user.is_active?
      start_new_session_for(user)
      audit("session.login", user, user: user)
      redirect_to after_login_path(user), notice: "Login realizado com sucesso."
    else
      audit("session.login_failed", user, user: user) if user
      flash.now[:alert] = "Usuário ou senha inválidos."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    audit("session.logout", current_user)
    terminate_session
    redirect_to login_path, notice: "Você saiu da sua conta."
  end

  private
    def after_login_path(user)
      return new_registration_company_path unless user.registration_complete?

      session.delete(:return_to) || root_path
    end
end
