module Members
  class DriversController < ApplicationController
    require_role :owner, :manager

    def new
      @user = User.new
      @user.build_driver
    end

    def create
      @user = User.new(driver_params)
      @user.role = :driver
      @user.is_active = true
      @user.company = current_company

      if @user.save
        redirect_to members_path, notice: "Motorista cadastrado com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private
      def driver_params
        params.require(:user).permit(
          :name, :username, :password, :password_confirmation,
          driver_attributes: %i[birthdate drive_license]
        )
      end
  end
end
