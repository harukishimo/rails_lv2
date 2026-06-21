module Exporters
  class SubmissionStatusesReport < BaseReport
    KEY = "submission_statuses"
    TITLE = "提出状況"
    HEADERS = [
      "提出物ID",
      "レビューID",
      "受験ID",
      "受験者",
      "受験対象",
      "提出種別",
      "タイトル",
      "GitHub URL",
      "ファイル添付",
      "作成日時"
    ].freeze

    def each_row
      return enum_for(:each_row) unless block_given?

      records = Submission.includes(
        file_attachment: :blob,
        review_application: {
          exam_application: [
            :candidate,
            { evaluation_target: %i[programming_language framework skill_level] }
          ]
        }
      )
      batch_each(records) do |submission|
        review_application = submission.review_application
        exam_application = review_application.exam_application

        yield [
          submission.id,
          review_application.id,
          exam_application.id,
          exam_application.candidate.name,
          exam_application.evaluation_target.display_name,
          submission.kind,
          submission.title,
          submission.github_url,
          submission.file.attached? ? submission.file.filename.to_s : nil,
          submission.created_at.iso8601
        ]
      end
    end
  end
end
