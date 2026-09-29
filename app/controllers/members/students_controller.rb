module Members
  class StudentsController < ApplicationController
    require_role :owner, :manager

    def new
      @user = User.new
      @user.build_student.build_address
      prepare_new_college_fields
      load_colleges
    end

    def create
      @user = User.new(student_params)
      @user.role = :student
      @user.is_active = true
      @user.company = current_company
      assign_company_to_new_college

      if @user.save
        redirect_to members_path, notice: "Aluno cadastrado com sucesso."
      else
        prepare_new_college_fields
        load_colleges
        render :new, status: :unprocessable_entity
      end
    end

    private
      def student_params
        params.require(:user).permit(
          :name, :email, :password, :password_confirmation,
          student_attributes: [
            :cpf, :birthdate, :gender, :college_id,
            address_attributes: %i[street number complement neighborhood city country zip_code],
            college_attributes: [
              :name,
              address_attributes: %i[street number complement neighborhood city country zip_code]
            ]
          ]
        )
      end

      def load_colleges
        @colleges = current_company.colleges.includes(:address).order(:name).map { |college| [ college.label_with_city, college.id ] }
      end

      def assign_company_to_new_college
        college = @user.student&.college
        college.address.company = current_company if college&.new_record? && college.address
      end

      def prepare_new_college_fields
        student = @user.student || @user.build_student
        college = student.college || student.build_college
        college.address || college.build_address
      end
  end
end
