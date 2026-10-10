module Members
  class StudentsController < ApplicationController
    include MemberEditing

    require_role :owner, :manager

    before_action :set_user, only: %i[edit update]

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
        audit("member.created", @user)
        redirect_to members_path, notice: "Aluno cadastrado com sucesso."
      else
        prepare_new_college_fields
        load_colleges
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      load_colleges
    end

    def update
      if @user.update(without_blank_password(student_update_params))
        audit("member.updated", @user, **Log.changes_of(@user, @user.student, @user.student.address))
        redirect_to members_path, notice: "Aluno atualizado com sucesso."
      else
        load_colleges
        render :edit, status: :unprocessable_entity
      end
    end

    private
      def set_user
        @user = find_member(:student)
        redirect_to members_path, alert: "Cadastro de aluno incompleto." unless @user.student
      end

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

      # Na edição a faculdade só pode ser trocada por uma já cadastrada.
      def student_update_params
        params.require(:user).permit(
          :name, :email, :password, :password_confirmation,
          student_attributes: [
            :id, :cpf, :birthdate, :gender, :college_id,
            address_attributes: %i[id street number complement neighborhood city country zip_code]
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
