require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  test "root responds successfully" do
    get root_url

    assert_response :success
    assert_includes response.body, "SkillEvidenceHub"
  end

  test "rails health endpoint responds successfully" do
    get rails_health_check_url

    assert_response :success
  end
end
