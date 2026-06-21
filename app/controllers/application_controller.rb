class ApplicationController < ActionController::Base
  include AuthorizationAuditLogging
  include Pundit::Authorization

  after_action :verify_pundit_authorization, unless: :skip_pundit_verification?

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized(exception)
    log_authorization_denial(exception)

    respond_to do |format|
      format.html { render plain: "Forbidden", status: :forbidden }
      format.json { render json: { error: { code: "forbidden", message: "権限がありません" } }, status: :forbidden }
      format.any { render plain: "Forbidden", status: :forbidden }
    end
  end

  def verify_pundit_authorization
    action_name == "index" ? verify_policy_scoped : verify_authorized
  end

  def skip_pundit_verification?
    respond_to?(:devise_controller?) && devise_controller?
  end
end
