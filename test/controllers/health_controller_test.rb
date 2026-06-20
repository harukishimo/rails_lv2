require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  test "app health page responds successfully" do
    get app_health_url

    assert_response :success
    assert_includes response.body, "SkillEvidenceHub"
  end

  test "rails health endpoint responds successfully" do
    get rails_health_check_url

    assert_response :success
  end
end
