module Api
  module V1
    class BaseController < ActionController::API
      include AuthorizationAuditLogging
      include Pundit::Authorization

      after_action :verify_pundit_authorization

      rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

      private

      def authenticate_api_user!
        @current_api_user = JwtToken.user_for(bearer_token)
        render_unauthorized("invalid_token", "有効なアクセストークンが必要です") unless @current_api_user
      rescue JwtToken::ExpiredTokenError
        render_unauthorized("token_expired", "アクセストークンの有効期限が切れています")
      rescue JwtToken::InvalidTokenError
        render_unauthorized("invalid_token", "アクセストークンが不正です")
      end

      attr_reader :current_api_user

      def bearer_token
        scheme, token = request.authorization.to_s.split(" ", 2)
        token if scheme&.casecmp("Bearer")&.zero?
      end

      def render_unauthorized(code, message)
        render json: { error: { code: code, message: message } }, status: :unauthorized
      end

      def pundit_user
        current_api_user
      end

      def user_not_authorized(exception)
        log_authorization_denial(exception)

        render json: { error: { code: "forbidden", message: "権限がありません" } }, status: :forbidden
      end

      def verify_pundit_authorization
        action_name == "index" ? verify_policy_scoped : verify_authorized
      end
    end
  end
end
