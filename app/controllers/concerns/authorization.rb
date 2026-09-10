module Authorization
  extend ActiveSupport::Concern

  included do
    helper_method :current_company
  end

  class_methods do
    def require_role(*roles, **options)
      allowed_roles = roles.map(&:to_s)

      before_action(**options) do
        unless current_user && allowed_roles.include?(current_user.role)
          redirect_to root_path, alert: "Você não tem permissão para acessar essa página."
        end
      end
    end
  end

  private
    def current_company
      current_user&.company
    end
end
