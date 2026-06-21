module Exporters
  class ReviewResultsReport < BaseReport
    KEY = "review_results"
    TITLE = "レビュー結果"
    HEADERS = [
      "レビューID",
      "受験ID",
      "受験者",
      "受験対象",
      "ステータス",
      "判定者",
      "提出日時",
      "判定日時",
      "更新日時"
    ].freeze

    def each_row
      return enum_for(:each_row) unless block_given?

      records = ReviewApplication.includes(
        :decided_by,
        exam_application: [
          :candidate,
          { evaluation_target: %i[programming_language framework skill_level] }
        ]
      )
      batch_each(records) do |review_application|
        exam_application = review_application.exam_application

        yield [
          review_application.id,
          exam_application.id,
          exam_application.candidate.name,
          exam_application.evaluation_target.display_name,
          review_application.status,
          review_application.decided_by&.name,
          review_application.submitted_at&.iso8601,
          review_application.decided_at&.iso8601,
          review_application.updated_at.iso8601
        ]
      end
    end
  end
end
