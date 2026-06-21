module Exporters
  class UserQualificationsReport < BaseReport
    KEY = "user_qualifications"
    TITLE = "取得資格"
    HEADERS = [
      "取得資格ID",
      "ユーザー",
      "メール",
      "受験対象",
      "取得日",
      "判定者",
      "根拠受験ID",
      "失効日時"
    ].freeze

    def each_row
      return enum_for(:each_row) unless block_given?

      records = UserQualification.includes(
        :user,
        :granted_by,
        :exam_application,
        evaluation_target: %i[programming_language framework skill_level]
      )
      batch_each(records) do |qualification|
        yield [
          qualification.id,
          qualification.user.name,
          qualification.user.email,
          qualification.evaluation_target.display_name,
          qualification.acquired_on.iso8601,
          qualification.granted_by.name,
          qualification.exam_application_id,
          qualification.revoked_at&.iso8601
        ]
      end
    end
  end
end
