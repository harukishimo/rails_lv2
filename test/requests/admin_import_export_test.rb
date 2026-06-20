require "test_helper"
require "tempfile"

class AdminImportExportTest < ActionDispatch::IntegrationTest
  test "admin can preview evaluation target import with row errors" do
    admin = create_user_with_role(Role::ADMIN)
    token = SecureRandom.hex(4)
    before_count = EvaluationTarget.count
    sign_in_as(admin)

    with_csv_upload(<<~CSV) do |file|
      skill_area,programming_language,framework,skill_level,skill_level_numeric_level,external_knowledge_key,version
      Backend #{token},Ruby #{token},Rails #{token},Lv2,2,rails_lv2_#{token},2026.06
      Backend #{token},Ruby #{token},Rails #{token},,2,,2026.06-error
    CSV
      post preview_admin_evaluation_target_import_path, params: { file: file }
    end

    assert_response :success
    assert_includes response.body, "取込結果"
    assert_includes response.body, "skill_level_code is required"
    assert_equal before_count, EvaluationTarget.count
  end

  test "admin can import evaluation targets" do
    admin = create_user_with_role(Role::ADMIN)
    token = SecureRandom.hex(4)
    sign_in_as(admin)

    with_csv_upload(<<~CSV) do |file|
      skill_area,programming_language,framework,skill_level,skill_level_numeric_level,external_knowledge_key,version
      Backend #{token},Ruby #{token},Rails #{token},Lv2,2,rails_lv2_#{token},2026.06
    CSV
      post import_admin_evaluation_target_import_path, params: { file: file }
    end

    assert_response :success
    assert_includes response.body, "取込結果"
    assert_equal "Ruby #{token} Rails #{token} Lv2 2026.06",
                 EvaluationTarget.find_by!(external_knowledge_key: "rails_lv2_#{token}").display_name
  end

  test "admin sees file-level error for corrupt xlsx import preview" do
    admin = create_user_with_role(Role::ADMIN)
    sign_in_as(admin)

    with_upload("broken.xlsx", "not an xlsx", content_type: Exporters::XlsxRenderer::CONTENT_TYPE) do |file|
      post preview_admin_evaluation_target_import_path, params: { file: file }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "XLSXファイルを読み取れません"
  end

  test "candidate cannot access import and export admin pages" do
    candidate = create_user_with_role(Role::CANDIDATE)
    sign_in_as(candidate)

    get new_admin_evaluation_target_import_path
    assert_response :forbidden

    get admin_exports_path
    assert_response :forbidden
  end

  test "admin can download csv and xlsx reports" do
    admin = create_user_with_role(Role::ADMIN)
    target = create_evaluation_target
    sign_in_as(admin)

    get admin_export_path("evaluation_targets", format: :csv)
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_includes response.body, "技術領域"
    assert_includes response.body, target.programming_language.name

    get admin_export_path("evaluation_targets", format: :xlsx)
    assert_response :success
    assert_equal Exporters::XlsxRenderer::CONTENT_TYPE, response.media_type
    assert response.body.start_with?("PK")
  end

  private

  def with_csv_upload(content)
    with_upload("targets.csv", content, content_type: "text/csv") do |file|
      yield file
    end
  end

  def with_upload(filename, content, content_type:)
    Tempfile.create([ "upload", File.extname(filename) ]) do |tempfile|
      tempfile.write(content)
      tempfile.flush
      yield Rack::Test::UploadedFile.new(tempfile.path, content_type, original_filename: filename)
    end
  end

  def create_evaluation_target
    token = SecureRandom.hex(4)
    language = ProgrammingLanguage.create!(name: "Ruby #{token}")
    framework = Framework.create!(name: "Rails #{token}", programming_language: language)
    EvaluationTarget.create!(
      skill_area: SkillArea.create!(name: "Backend #{token}"),
      programming_language: language,
      framework: framework,
      skill_level: SkillLevel.create!(code: "Lv#{rand(10_000..99_999)}", numeric_level: 2),
      external_knowledge_key: "rails_lv2_#{token}",
      version: "2026.06-#{token}"
    )
  end

  def create_user_with_role(code)
    role = Role.find_or_create_by!(code: code) do |record|
      record.name = Role::NAMES.fetch(code)
    end
    user = User.create!(
      name: "User",
      email: "user-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    UserRole.create!(user: user, role: role)
    user
  end

  def sign_in_as(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
  end
end
