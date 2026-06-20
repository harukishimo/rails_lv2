require "test_helper"

class EvaluationMasterTest < ActiveSupport::TestCase
  test "skill area name is unique and soft deleted records are hidden" do
    name = "Backend #{SecureRandom.hex(4)}"
    area = SkillArea.create!(name: name, display_order: 1)
    duplicate = SkillArea.new(name: name, display_order: 2)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"

    area.destroy

    assert_not SkillArea.exists?(area.id)
    assert SkillArea.with_deleted.exists?(area.id)
  end

  test "programming language name is unique" do
    name = "Ruby #{SecureRandom.hex(4)}"
    ProgrammingLanguage.create!(name: name)
    duplicate = ProgrammingLanguage.new(name: name)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "framework name is unique per programming language" do
    ruby = ProgrammingLanguage.create!(name: "Ruby #{SecureRandom.hex(4)}")
    go = ProgrammingLanguage.create!(name: "Go #{SecureRandom.hex(4)}")
    Framework.create!(name: "Web", programming_language: ruby)

    duplicate = Framework.new(name: "Web", programming_language: ruby)
    same_name_for_other_language = Framework.new(name: "Web", programming_language: go)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
    assert same_name_for_other_language.valid?
  end

  test "skill level requires positive numeric level" do
    level = SkillLevel.new(code: "Lv0", numeric_level: 0)

    assert_not level.valid?
    assert_includes level.errors[:numeric_level], "must be greater than 0"
  end
end
