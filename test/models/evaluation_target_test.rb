require "test_helper"

class EvaluationTargetTest < ActiveSupport::TestCase
  test "valid target keeps external knowledge reference without criteria body" do
    target = build_evaluation_target

    assert target.valid?
    assert_includes target.display_name, target.programming_language.name
    assert_includes target.display_name, target.framework.name
    assert_includes target.display_name, target.skill_level.code
    assert_includes target.display_name, target.version
  end

  test "requires external knowledge url or key" do
    target = build_evaluation_target(external_knowledge_url: nil, external_knowledge_key: nil)

    assert_not target.valid?
    assert_includes target.errors[:base], "external knowledge url or key is required"
  end

  test "external knowledge url must be http or https" do
    target = build_evaluation_target(external_knowledge_url: "ftp://example.com/ruby-lv2")

    assert_not target.valid?
    assert_includes target.errors[:external_knowledge_url], "must be an HTTP or HTTPS URL"
  end

  test "prevents duplicate active target identity" do
    target = create_evaluation_target
    duplicate = build_evaluation_target(
      skill_area: target.skill_area,
      programming_language: target.programming_language,
      framework: target.framework,
      skill_level: target.skill_level,
      version: target.version
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:base], "evaluation target identity has already been taken"
  end

  test "framework must match programming language" do
    ruby = create_language("Ruby #{SecureRandom.hex(4)}")
    go = create_language("Go #{SecureRandom.hex(4)}")
    framework = Framework.create!(name: "Ruby on Rails", programming_language: ruby)
    target = build_evaluation_target(programming_language: go, framework: framework)

    assert_not target.valid?
    assert_includes target.errors[:framework], "must belong to the selected programming language"
  end

  test "soft deleted targets are hidden from normal queries" do
    target = create_evaluation_target

    target.destroy

    assert_not EvaluationTarget.exists?(target.id)
    assert EvaluationTarget.with_deleted.exists?(target.id)
  end

  test "identity can be reused after soft delete" do
    target = create_evaluation_target
    target.destroy

    recreated = build_evaluation_target(
      skill_area: target.skill_area,
      programming_language: target.programming_language,
      framework: target.framework,
      skill_level: target.skill_level,
      version: target.version
    )

    assert recreated.save
  end

  private

  def build_evaluation_target(attributes = {})
    defaults = {
      skill_area: SkillArea.create!(name: "Backend #{SecureRandom.hex(4)}"),
      programming_language: create_language("Ruby #{SecureRandom.hex(4)}"),
      framework: nil,
      skill_level: SkillLevel.create!(code: "Lv#{rand(1000..9999)}", numeric_level: 2),
      external_knowledge_url: "https://example.com/internal-knowledge/ruby-on-rails/lv2",
      external_knowledge_key: "ruby_on_rails_lv2_#{SecureRandom.hex(4)}",
      version: "2026.06-#{SecureRandom.hex(4)}",
      active: true
    }.merge(attributes)

    defaults[:framework] ||= Framework.create!(
      name: "Ruby on Rails #{SecureRandom.hex(4)}",
      programming_language: defaults.fetch(:programming_language)
    )

    EvaluationTarget.new(defaults)
  end

  def create_evaluation_target(attributes = {})
    build_evaluation_target(attributes).tap(&:save!)
  end

  def create_language(name)
    ProgrammingLanguage.create!(name: name)
  end
end
