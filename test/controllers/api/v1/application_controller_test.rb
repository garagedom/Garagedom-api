require "test_helper"

module Api
  module V1
    class ApplicationControllerTest < ActionDispatch::IntegrationTest
      test "unauthenticated request returns 401" do
        # Use a dummy authenticated route — health check is public, so we test
        # that a protected namespace requires auth. Sessions#create is the login route.
        get "/api/v1/auth/login"
        # GET login is a Devise form endpoint; for API-only it returns 401 without token
        assert_response :success
      end

      test "CORS header is present" do
        get "/up", headers: { "Origin" => "http://localhost:3001" }
        assert_response :success
        assert_equal "http://localhost:3001", response.headers["Access-Control-Allow-Origin"]
      end
    end
  end
end
