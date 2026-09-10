module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    before_action :require_completed_registration

    helper_method :current_user, :user_signed_in?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
      skip_before_action :require_completed_registration, **options
    end

    def allow_incomplete_registration(**options)
      skip_before_action :require_completed_registration, **options
    end
  end

  private
    def current_user
      Current.user ||= authenticated_user_from_session
    end

    def authenticated_user_from_session
      User.find_by(id: session[:user_id])
    end

    def user_signed_in?
      current_user.present?
    end

    def require_authentication
      redirect_to login_path, alert: "Faça login para continuar." unless current_user
    end

    def require_completed_registration
      return unless current_user
      return if current_user.registration_complete?

      redirect_to new_registration_company_path, alert: "Finalize o cadastro da sua empresa para continuar."
    end

    def start_new_session_for(user)
      reset_session
      session[:user_id] = user.id
      Current.user = user
    end

    def terminate_session
      Current.user = nil
      reset_session
    end
end
