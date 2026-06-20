require "test_helper"

class MissingWebAuthorizationController < ApplicationController
  def show
    render plain: "missing authorization"
  end
end

module Api
  module V1
    class MissingAuthorizationController < BaseController
      def show
        render json: { status: "missing authorization" }
      end
    end
  end
end

class PunditVerificationTest < ActionDispatch::IntegrationTest
  test "web controllers require authorize or policy_scope" do
    with_routing do |routes|
      routes.draw { get "/missing-web-authorization", to: "missing_web_authorization#show" }

      assert_raises Pundit::AuthorizationNotPerformedError do
        get "/missing-web-authorization"
      end
    end
  end

  test "API controllers require authorize or policy_scope" do
    with_routing do |routes|
      routes.draw { get "/api/v1/missing-authorization", to: "api/v1/missing_authorization#show" }

      assert_raises Pundit::AuthorizationNotPerformedError do
        get "/api/v1/missing-authorization"
      end
    end
  end
end
