module Auditing
  extend ActiveSupport::Concern

  private
    def audit(action, auditable = nil, user: current_user, **details)
      return unless user

      Log.record!(user: user, action: action, auditable: auditable, details: details, ip_address: request.remote_ip)
    end
end
