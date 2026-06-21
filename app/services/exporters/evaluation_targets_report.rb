module Exporters
  class EvaluationTargetsReport < BaseReport
    KEY = "evaluation_targets"
    TITLE = "受験対象マスタ"
    HEADERS = [
      "ID",
      "技術領域",
      "言語",
      "フレームワーク",
      "レベル",
      "外部ナレッジURL",
      "外部ナレッジキー",
      "バージョン",
      "説明",
      "表示順",
      "有効"
    ].freeze

    def each_row
      return enum_for(:each_row) unless block_given?

      batch_each(EvaluationTarget.includes(:skill_area, :programming_language, :framework, :skill_level)) do |target|
        yield [
          target.id,
          target.skill_area.name,
          target.programming_language.name,
          target.framework&.name,
          target.skill_level.code,
          target.external_knowledge_url,
          target.external_knowledge_key,
          target.version,
          target.description,
          target.display_order,
          target.active?
        ]
      end
    end
  end
end
