module Members
  class DriversController < ApplicationController
    include MemberEditing

    require_role :owner, :manager

    before_action :set_user, only: %i[edit update]

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
        audit("member.created", @user)
        redirect_to members_path, notice: "Motorista cadastrado com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @user.update(without_blank_password(driver_params))
        audit("member.updated", @user, **Log.changes_of(@user, @user.driver))
        redirect_to members_path, notice: "Motorista atualizado com sucesso."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private
      def set_user
        @user = find_member(:driver)
        @user.driver || @user.build_driver
      end

      def driver_params
        params.require(:user).permit(
          :name, :email, :password, :password_confirmation,
          driver_attributes: %i[id birthdate drive_license]
        )
      end
  end
end
