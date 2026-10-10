# Apoio às telas de edição de membros (secretarias, motoristas e alunos).
module MemberEditing
  extend ActiveSupport::Concern

  private
    def find_member(role)
      current_company.employees.where(role: role).find(params[:id])
    end

    # Senha em branco na edição mantém a senha atual.
    def without_blank_password(attributes)
      attributes[:password].blank? ? attributes.except(:password, :password_confirmation) : attributes
    end
end
