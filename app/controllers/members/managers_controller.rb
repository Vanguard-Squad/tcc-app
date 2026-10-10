module Members
  class ManagersController < ApplicationController
    include MemberEditing

    require_role :owner

    before_action :set_user, only: %i[edit update]

    def new
      @user = User.new
    end

    def create
      @user = User.new(manager_params)
      @user.role = :manager
      @user.is_active = true
      @user.company = current_company

      if @user.save
        audit("member.created", @user)
        redirect_to members_path, notice: "Secretaria cadastrada com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @user.update(without_blank_password(manager_params))
        audit("member.updated", @user, **Log.changes_of(@user))
        redirect_to members_path, notice: "Secretaria atualizada com sucesso."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private
      def set_user
        @user = find_member(:manager)
      end

      def manager_params
        params.require(:user).permit(:name, :email, :password, :password_confirmation)
      end
  end
end
