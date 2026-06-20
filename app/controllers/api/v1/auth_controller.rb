module Api
  module V1
    class AuthController < BaseController
      before_action :authenticate_api_user!, only: :me

      def login
        user = User.find_for_database_authentication(email: login_params[:email].to_s.downcase)

        if user&.valid_password?(login_params[:password]) && user.active_for_authentication?
          render json: token_response_for(user), status: :created
        else
          render_unauthorized("invalid_credentials", "メールアドレスまたはパスワードが正しくありません")
        end
      end

      def refresh
        rotated = RefreshToken.rotate!(params[:refresh_token])

        if rotated
          _record, raw_refresh_token = rotated
          render json: token_response_for(_record.user, refresh_token: raw_refresh_token), status: :created
        else
          render_unauthorized("invalid_refresh_token", "リフレッシュトークンが不正です")
        end
      end

      def logout
        RefreshToken.authenticate(params[:refresh_token])&.revoke!
        head :no_content
      end

      def me
        render json: {
          user: {
            id: current_api_user.id,
            name: current_api_user.name,
            email: current_api_user.email
          }
        }
      end

      private

      def login_params
        params.require(:auth).permit(:email, :password)
      end

      def token_response_for(user, refresh_token: nil)
        refresh_token ||= RefreshToken.issue_for!(user).last

        {
          access_token: JwtToken.issue_for(user),
          token_type: "Bearer",
          expires_in: JwtToken::DEFAULT_TTL.to_i,
          refresh_token: refresh_token
        }
      end
    end
  end
end
