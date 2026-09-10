module Members
  class ManagersController < ApplicationController
    require_role :owner

    def new
      @user = User.new
    end

    def create
      @user = User.new(manager_params)
      @user.role = :manager
      @user.is_active = true
      @user.company = current_company

      if @user.save
        redirect_to members_path, notice: "Secretaria cadastrada com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private
      def manager_params
        params.require(:user).permit(:name, :username, :password, :password_confirmation)
      end
  end
end
