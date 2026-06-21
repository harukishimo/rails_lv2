require "test_helper"

class EvaluationTargetImportRowTest < ActiveSupport::TestCase
  test "keeps only permitted attributes and freezes imported row values" do
    row = EvaluationTargets::ImportRow.new(
      number: 2,
      attributes: {
        skill_area_name: "Backend",
        programming_language_name: "Ruby",
        unsafe_formula: "=IMPORTDATA()"
      }
    )

    assert row.frozen?
    assert row.attributes.frozen?
    assert_equal 2, row.number
    assert_equal "Backend", row[:skill_area_name]
    assert_equal "Ruby", row[:programming_language_name]
    assert_nil row[:unsafe_formula]
    assert_equal({ skill_area_name: "Backend", programming_language_name: "Ruby" }, row.to_h)
  end

  test "permitted attribute constants are immutable" do
    assert EvaluationTargets::ImportRow::PERMITTED_ATTRIBUTES.frozen?
    assert_raises(FrozenError) do
      EvaluationTargets::ImportRow::PERMITTED_ATTRIBUTES << :unsafe
    end
  end
end
