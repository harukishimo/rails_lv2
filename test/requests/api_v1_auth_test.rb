require "test_helper"

class ApiV1AuthTest < ActionDispatch::IntegrationTest
  test "valid API credentials issue access and refresh tokens" do
    user = create_user

    post api_v1_auth_login_path, params: {
      auth: {
        email: user.email,
        password: "password123"
      }
    }

    assert_response :created
    body = response.parsed_body
    assert_equal "Bearer", body.fetch("token_type")
    assert body.fetch("access_token").present?
    assert body.fetch("refresh_token").present?
    assert_equal 15.minutes.to_i, body.fetch("expires_in")
  end

  test "invalid API credentials are rejected" do
    user = create_user

    post api_v1_auth_login_path, params: {
      auth: {
        email: user.email,
        password: "wrong-password"
      }
    }

    assert_response :unauthorized
    assert_equal "invalid_credentials", response.parsed_body.dig("error", "code")
  end

  test "inactive users cannot login through API" do
    user = create_user(active: false)

    post api_v1_auth_login_path, params: {
      auth: {
        email: user.email,
        password: "password123"
      }
    }

    assert_response :unauthorized
    assert_equal "invalid_credentials", response.parsed_body.dig("error", "code")
  end

  test "bearer access token returns current user" do
    user = create_user
    access_token = JwtToken.issue_for(user)

    get api_v1_auth_me_path, headers: { "Authorization" => "Bearer #{access_token}" }

    assert_response :success
    assert_equal user.email, response.parsed_body.dig("user", "email")
  end

  test "inactive users cannot use an existing bearer access token" do
    user = create_user
    access_token = JwtToken.issue_for(user)
    user.update!(active: false)

    get api_v1_auth_me_path, headers: { "Authorization" => "Bearer #{access_token}" }

    assert_response :unauthorized
    assert_equal "invalid_token", response.parsed_body.dig("error", "code")
  end

  test "refresh rotates token and rejects old refresh token" do
    user = create_user
    _record, raw_refresh_token = RefreshToken.issue_for!(user)

    post api_v1_auth_refresh_path, params: { refresh_token: raw_refresh_token }

    assert_response :created
    new_refresh_token = response.parsed_body.fetch("refresh_token")
    assert_not_equal raw_refresh_token, new_refresh_token

    post api_v1_auth_refresh_path, params: { refresh_token: raw_refresh_token }

    assert_response :unauthorized
    assert_equal "invalid_refresh_token", response.parsed_body.dig("error", "code")
  end

  test "inactive users cannot refresh an existing refresh token" do
    user = create_user
    _record, raw_refresh_token = RefreshToken.issue_for!(user)
    user.update!(active: false)

    post api_v1_auth_refresh_path, params: { refresh_token: raw_refresh_token }

    assert_response :unauthorized
    assert_equal "invalid_refresh_token", response.parsed_body.dig("error", "code")
  end

  test "logout revokes refresh token" do
    user = create_user
    _record, raw_refresh_token = RefreshToken.issue_for!(user)

    delete api_v1_auth_logout_path, params: { refresh_token: raw_refresh_token }

    assert_response :no_content
    assert_nil RefreshToken.authenticate(raw_refresh_token)
  end

  test "missing bearer token is rejected" do
    get api_v1_auth_me_path

    assert_response :unauthorized
    assert_equal "invalid_token", response.parsed_body.dig("error", "code")
  end

  private

  def create_user(active: true)
    User.create!(
      name: "Candidate",
      email: "candidate-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      active: active
    )
  end
end
