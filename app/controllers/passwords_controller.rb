# Troca da própria senha. Obrigatória no primeiro acesso do aluno, que entra
# com a senha provisória cadastrada pela secretaria.
class PasswordsController < ApplicationController
  allow_pending_password_change
  allow_pending_contract

  def edit
  end

  def update
    unless current_user.authenticate(params[:current_password].to_s)
      flash.now[:alert] = "A senha atual está incorreta."
      return render :edit, status: :unprocessable_entity
    end

    if params[:password].blank?
      flash.now[:alert] = "Informe a nova senha."
      return render :edit, status: :unprocessable_entity
    end

    if params[:password] == params[:current_password]
      flash.now[:alert] = "A nova senha precisa ser diferente da senha provisória."
      return render :edit, status: :unprocessable_entity
    end

    if current_user.update(password: params[:password], password_confirmation: params[:password_confirmation], must_change_password: false)
      audit("session.password_changed", current_user)
      redirect_to root_path, notice: "Senha alterada com sucesso."
    else
      flash.now[:alert] = current_user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end
end
