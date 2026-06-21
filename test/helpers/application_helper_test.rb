require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "enum labels are localized without changing enum values" do
    I18n.with_locale(:ja) do
      assert_equal "受験表明済み", enum_label(ExamApplication, :status, "declared")
      assert_equal "合格", enum_label(InterviewResult, :result, "passed")
      assert_equal [ [ "ファイル", "file" ], [ "GitHubリポジトリ", "github_repository" ], [ "補足資料", "supplement" ] ],
                   enum_options_for(Submission, :kind)
    end

    assert_equal %w[draft declared reviewing review_approved interview_requested interview_scheduled passed failed canceled closed],
                 ExamApplication.statuses.keys
  end

  test "status badge falls back to shared Japanese labels" do
    I18n.with_locale(:ja) do
      badge = status_badge("calendar_created")

      assert_includes badge, "カレンダー登録済み"
      assert_includes badge, "bg-emerald-100"
    end
  end

  test "status transition text is localized for stored events" do
    event = StatusChangeEvent.new(from_status: "draft", to_status: "submitted")

    I18n.with_locale(:ja) do
      assert_equal "下書き → 提出済み", status_transition_label(event)
      assert_equal "下書きから提出済みへ変更しました", status_transition_message(event)
    end
  end
end
