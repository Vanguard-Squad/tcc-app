module Members
  class StudentsController < ApplicationController
    require_role :owner, :manager

    def new
      @user = User.new
      @user.build_student.build_address
      @colleges = College.order(:name)
    end

    def create
      @user = User.new(student_params)
      @user.role = :student
      @user.is_active = true
      @user.company = current_company
      @colleges = College.order(:name)

      if @user.save
        redirect_to members_path, notice: "Aluno cadastrado com sucesso."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private
      def student_params
        params.require(:user).permit(
          :name, :username, :password, :password_confirmation,
          student_attributes: [
            :cpf, :birthdate, :gender, :college_id,
            address_attributes: %i[street number complement neighborhood country zip_code]
          ]
        )
      end
  end
end
