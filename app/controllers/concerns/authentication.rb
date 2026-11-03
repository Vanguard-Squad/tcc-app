module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    before_action :require_completed_registration
    before_action :require_password_change
    before_action :require_approved_contract

    helper_method :current_user, :user_signed_in?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
      skip_before_action :require_completed_registration, **options
      skip_before_action :require_password_change, **options
      skip_before_action :require_approved_contract, **options
    end

    def allow_pending_password_change(**options)
      skip_before_action :require_password_change, **options
    end

    def allow_pending_contract(**options)
      skip_before_action :require_approved_contract, **options
    end

    def allow_incomplete_registration(**options)
      skip_before_action :require_completed_registration, **options
    end
  end

  private
    def current_user
      Current.user ||= authenticated_user_from_session
    end

    # Usuário desativado perde a sessão na próxima requisição.
    def authenticated_user_from_session
      User.find_by(id: session[:user_id], is_active: true)
    end

    def user_signed_in?
      current_user.present?
    end

    def require_authentication
      return if current_user

      session[:return_to] = request.fullpath if request.get?
      redirect_to login_path, alert: "Faça login para continuar."
    end

    def require_completed_registration
      return unless current_user
      return if current_user.registration_complete?

      redirect_to new_registration_company_path, alert: "Finalize o cadastro da sua empresa para continuar."
    end

    # Senha criada pela secretaria é provisória: o aluno troca no primeiro acesso.
    def require_password_change
      redirect_to edit_password_path if current_user&.must_change_password?
    end

    # Aluno só usa o sistema depois que a secretaria aprova o contrato assinado.
    def require_approved_contract
      return unless current_user&.student? && current_user.student
      return if current_user.student.contract_approved?

      redirect_to students_contract_path
    end

    def start_new_session_for(user)
      return_to = session[:return_to]
      reset_session
      session[:return_to] = return_to if return_to
      session[:user_id] = user.id
      Current.user = user
    end

    def terminate_session
      Current.user = nil
      reset_session
    end
end
