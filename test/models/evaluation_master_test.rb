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
    assert SkillArea.create!(name: name, display_order: 3)
  end

  test "skill area restore does not create active duplicate" do
    name = "Backend #{SecureRandom.hex(4)}"
    deleted_area = SkillArea.create!(name: name, display_order: 1)
    deleted_area.destroy
    SkillArea.create!(name: name, display_order: 2)

    assert_no_difference -> { SkillArea.where(name: name).count } do
      deleted_area.restore(recursive: false)
    end
    assert deleted_area.reload.deleted?
    assert_includes deleted_area.errors[:base], "cannot restore because active duplicate exists"
  end

  test "programming language name is unique" do
    name = "Ruby #{SecureRandom.hex(4)}"
    ProgrammingLanguage.create!(name: name)
    duplicate = ProgrammingLanguage.new(name: name)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"

    ProgrammingLanguage.find_by!(name: name).destroy
    assert ProgrammingLanguage.create!(name: name)
  end

  test "programming language restore does not create active duplicate" do
    name = "Ruby #{SecureRandom.hex(4)}"
    deleted_language = ProgrammingLanguage.create!(name: name)
    deleted_language.destroy
    ProgrammingLanguage.create!(name: name)

    assert_no_difference -> { ProgrammingLanguage.where(name: name).count } do
      deleted_language.restore(recursive: false)
    end
    assert deleted_language.reload.deleted?
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

    Framework.find_by!(name: "Web", programming_language: ruby).destroy
    assert Framework.create!(name: "Web", programming_language: ruby)
  end

  test "framework restore does not create active duplicate for same language" do
    ruby = ProgrammingLanguage.create!(name: "Ruby #{SecureRandom.hex(4)}")
    deleted_framework = Framework.create!(name: "Web", programming_language: ruby)
    deleted_framework.destroy
    Framework.create!(name: "Web", programming_language: ruby)

    assert_no_difference -> { Framework.where(name: "Web", programming_language: ruby).count } do
      deleted_framework.restore(recursive: false)
    end
    assert deleted_framework.reload.deleted?
  end

  test "skill level requires positive numeric level" do
    level = SkillLevel.new(code: "Lv0", numeric_level: 0)

    assert_not level.valid?
    assert_includes level.errors[:numeric_level], "must be greater than 0"
  end

  test "skill level code can be reused after soft delete" do
    code = "Lv#{rand(1000..9999)}"
    SkillLevel.create!(code: code, numeric_level: 2).destroy

    assert SkillLevel.create!(code: code, numeric_level: 2)
  end

  test "skill level restore does not create active duplicate" do
    code = "Lv#{rand(1000..9999)}"
    deleted_level = SkillLevel.create!(code: code, numeric_level: 2)
    deleted_level.destroy
    SkillLevel.create!(code: code, numeric_level: 2)

    assert_no_difference -> { SkillLevel.where(code: code).count } do
      deleted_level.restore(recursive: false)
    end
    assert deleted_level.reload.deleted?
  end
end
