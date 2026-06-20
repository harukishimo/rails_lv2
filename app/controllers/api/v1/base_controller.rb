module Api
  module V1
    class BaseController < ActionController::API
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
    end
  end
end
