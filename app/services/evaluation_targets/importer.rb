require "csv"
require "roo"
require "zip"

module EvaluationTargets
  class Importer
    class UnsupportedFileError < StandardError; end

    MAX_FILE_SIZE = 5.megabytes
    SAMPLE_BYTES = 4.kilobytes
    IMPORT_BATCH_SIZE = 100
    XSLX_MAGIC = "PK".b
    CSV_CONTENT_TYPES = %w[
      application/csv
      application/octet-stream
      application/vnd.ms-excel
      text/csv
      text/plain
    ].freeze
    XLSX_CONTENT_TYPES = %w[
      application/octet-stream
      application/zip
      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    ].freeze

    REQUIRED_ATTRIBUTES = %i[
      skill_area_name
      programming_language_name
      skill_level_code
      version
    ].freeze

    HEADER_ALIASES = {
      "skill_area" => :skill_area_name,
      "skill_area_name" => :skill_area_name,
      "技術領域" => :skill_area_name,
      "programming_language" => :programming_language_name,
      "programming_language_name" => :programming_language_name,
      "language" => :programming_language_name,
      "言語" => :programming_language_name,
      "framework" => :framework_name,
      "framework_name" => :framework_name,
      "フレームワーク" => :framework_name,
      "skill_level" => :skill_level_code,
      "skill_level_code" => :skill_level_code,
      "level" => :skill_level_code,
      "lv" => :skill_level_code,
      "レベル" => :skill_level_code,
      "external_knowledge_url" => :external_knowledge_url,
      "knowledge_url" => :external_knowledge_url,
      "外部ナレッジurl" => :external_knowledge_url,
      "external_knowledge_key" => :external_knowledge_key,
      "knowledge_key" => :external_knowledge_key,
      "外部ナレッジキー" => :external_knowledge_key,
      "version" => :version,
      "バージョン" => :version,
      "description" => :description,
      "説明" => :description,
      "display_order" => :display_order,
      "表示順" => :display_order,
      "active" => :active,
      "有効" => :active,
      "skill_level_numeric_level" => :skill_level_numeric_level,
      "numeric_level" => :skill_level_numeric_level,
      "数値レベル" => :skill_level_numeric_level
    }.freeze

    ImportRow = Struct.new(:number, :attributes, keyword_init: true) do
      def [](key)
        attributes[key]
      end
    end

    RowResult = Struct.new(:row_number, :status, :display_name, :errors, keyword_init: true) do
      def success?
        errors.blank?
      end
    end

    Result = Struct.new(:mode, :rows, keyword_init: true) do
      def processed_count
        rows.size
      end

      def created_count
        rows.count { |row| row.status == :created }
      end

      def updated_count
        rows.count { |row| row.status == :updated }
      end

      def failed_count
        rows.count { |row| row.errors.present? }
      end

      def success?
        failed_count.zero?
      end
    end

    def self.preview(file:)
      new(file: file).preview
    end

    def self.import(file:)
      new(file: file).import
    end

    def initialize(file:)
      @file = file
    end

    def preview
      validate_file!
      build_result(mode: :preview) { |row| preview_row(row) }
    rescue *parse_errors => e
      raise UnsupportedFileError, "ファイルを読み取れません: #{e.message}"
    end

    def import
      validate_file!
      build_result(mode: :import) { |row| import_row(row) }
    rescue *parse_errors => e
      raise UnsupportedFileError, "ファイルを読み取れません: #{e.message}"
    end

    private

    attr_reader :file

    def each_import_row(&block)
      return enum_for(:each_import_row) unless block

      case extension
      when ".csv"
        each_csv_row(&block)
      when ".xlsx"
        each_xlsx_row(&block)
      else
        raise UnsupportedFileError, "CSVまたはXLSXファイルを選択してください"
      end
    end

    def validate_file!
      raise UnsupportedFileError, "ファイルサイズは5MB以下にしてください" if file_size > MAX_FILE_SIZE

      case extension
      when ".csv"
        validate_content_type!(CSV_CONTENT_TYPES)
        validate_csv_content!
      when ".xlsx"
        validate_content_type!(XLSX_CONTENT_TYPES)
        validate_xlsx_content!
      else
        raise UnsupportedFileError, "CSVまたはXLSXファイルを選択してください"
      end
    end

    def validate_content_type!(allowed_content_types)
      return if content_type.blank?
      return if allowed_content_types.include?(content_type)

      raise UnsupportedFileError, "ファイル形式が拡張子と一致しません"
    end

    def validate_csv_content!
      sample = file_sample
      raise UnsupportedFileError, "CSVはUTF-8で保存してください" unless sample.force_encoding(Encoding::UTF_8).valid_encoding?
      raise UnsupportedFileError, "CSVに不正なバイナリ文字が含まれています" if sample.include?("\x00")
    end

    def validate_xlsx_content!
      return if file_sample(bytes: 2) == XSLX_MAGIC

      raise UnsupportedFileError, "XLSXファイルを読み取れません"
    end

    def each_csv_row
      CSV.foreach(path, headers: true, encoding: "bom|utf-8").with_index(2) do |csv_row, row_number|
        yield build_row(row_number, csv_row.to_h)
      end
    end

    def each_xlsx_row
      workbook = Roo::Spreadsheet.open(path, extension: :xlsx)
      headers = streamed_xlsx_values(workbook.each_row_streaming(max_rows: 1, pad_cells: true).first)

      workbook.each_row_streaming(offset: 1, pad_cells: true).with_index(2) do |row, row_number|
        yield build_row(row_number, headers.zip(streamed_xlsx_values(row)).to_h)
      end
    end

    def build_result(mode:)
      rows = []
      each_import_row.each_slice(IMPORT_BATCH_SIZE) do |batch|
        batch.each do |row|
          rows << yield(row)
        end
      end
      Result.new(mode: mode, rows: rows)
    end

    def build_row(row_number, raw_attributes)
      attributes = {}

      raw_attributes.each do |header, value|
        key = HEADER_ALIASES[normalize_header(header)]
        attributes[key] = normalize_value(value) if key.present?
      end

      ImportRow.new(number: row_number, attributes: attributes)
    end

    def preview_row(row)
      errors = row_validation_errors(row)
      return failed_result(row, errors) if errors.present?

      target = build_evaluation_target(row, persist_dependencies: false)
      return failed_result(row, target.errors.full_messages) unless target.valid?

      RowResult.new(
        row_number: row.number,
        status: existing_target?(row) ? :updated : :created,
        display_name: target.display_name,
        errors: []
      )
    end

    def import_row(row)
      errors = row_validation_errors(row)
      return failed_result(row, errors) if errors.present?

      EvaluationTarget.transaction(requires_new: true) do
        target = build_evaluation_target(row, persist_dependencies: true)
        created = target.new_record?
        target.save!

        RowResult.new(
          row_number: row.number,
          status: created ? :created : :updated,
          display_name: target.display_name,
          errors: []
        )
      end
    rescue ActiveRecord::RecordInvalid => e
      failed_result(row, e.record.errors.full_messages)
    end

    def build_evaluation_target(row, persist_dependencies:)
      skill_area = find_or_build_skill_area(row, persist: persist_dependencies)
      language = find_or_build_language(row, persist: persist_dependencies)
      framework = find_or_build_framework(row, language, persist: persist_dependencies)
      skill_level = find_or_build_skill_level(row, persist: persist_dependencies)
      target = find_existing_target(language, framework, skill_level, row[:version]) || EvaluationTarget.new

      target.assign_attributes(
        skill_area: skill_area,
        programming_language: language,
        framework: framework,
        skill_level: skill_level,
        external_knowledge_url: row[:external_knowledge_url],
        external_knowledge_key: row[:external_knowledge_key],
        description: row[:description],
        version: row[:version],
        display_order: parsed_integer(row[:display_order], default: 0),
        active: parsed_active(row)
      )
      target
    end

    def row_validation_errors(row)
      errors = REQUIRED_ATTRIBUTES.filter_map do |attribute|
        "#{attribute} is required" if row[attribute].blank?
      end

      if row[:external_knowledge_url].blank? && row[:external_knowledge_key].blank?
        errors << "external_knowledge_url or external_knowledge_key is required"
      end

      if row[:display_order].present? && parsed_integer(row[:display_order]).nil?
        errors << "display_order must be a non-negative integer"
      end

      if row[:skill_level_numeric_level].present? && parsed_integer(row[:skill_level_numeric_level], positive: true).nil?
        errors << "skill_level_numeric_level must be a positive integer"
      end

      errors << "active must be true or false" if row[:active].present? && parsed_boolean(row[:active]).nil?
      errors << "skill_level_numeric_level is required when skill_level_code does not contain a number" if numeric_level(row).nil?
      errors
    end

    def find_or_build_skill_area(row, persist:)
      find_or_build_case_insensitive(SkillArea.all, :name, row[:skill_area_name]).tap do |record|
        record.display_order ||= 0
        record.save! if persist && record.changed?
      end
    end

    def find_or_build_language(row, persist:)
      find_or_build_case_insensitive(ProgrammingLanguage.all, :name, row[:programming_language_name]).tap do |record|
        record.save! if persist && record.changed?
      end
    end

    def find_or_build_framework(row, language, persist:)
      return if row[:framework_name].blank?

      find_or_build_case_insensitive(Framework.where(programming_language: language), :name, row[:framework_name]).tap do |record|
        record.programming_language = language
        record.save! if persist && record.changed?
      end
    end

    def find_or_build_skill_level(row, persist:)
      find_or_build_case_insensitive(SkillLevel.all, :code, row[:skill_level_code]).tap do |record|
        record.numeric_level = numeric_level(row)
        record.save! if persist && record.changed?
      end
    end

    def find_or_build_case_insensitive(relation, column, value)
      find_case_insensitive(relation, column, value) || relation.klass.new(column => value)
    end

    def find_case_insensitive(relation, column, value)
      table = relation.klass.arel_table
      relation.where(Arel::Nodes::NamedFunction.new("LOWER", [ table[column] ]).eq(value.downcase)).first
    end

    def find_existing_target(language, framework, skill_level, version)
      return if language.new_record? || skill_level.new_record?
      return if framework&.new_record?

      EvaluationTarget.where(
        programming_language: language,
        framework: framework,
        skill_level: skill_level,
        version: version
      ).first
    end

    def existing_target?(row)
      language = find_case_insensitive(ProgrammingLanguage.all, :name, row[:programming_language_name])
      skill_level = find_case_insensitive(SkillLevel.all, :code, row[:skill_level_code])
      return false if language.blank? || skill_level.blank?

      framework = nil
      if row[:framework_name].present?
        framework = find_case_insensitive(Framework.where(programming_language: language), :name, row[:framework_name])
        return false if framework.blank?
      end

      EvaluationTarget.where(programming_language: language, framework: framework, skill_level: skill_level, version: row[:version]).exists?
    end

    def failed_result(row, errors)
      RowResult.new(row_number: row.number, status: :failed, display_name: nil, errors: errors)
    end

    def numeric_level(row)
      parsed_integer(row[:skill_level_numeric_level], positive: true) ||
        row[:skill_level_code].to_s[/\d+/]&.to_i
    end

    def parsed_active(row)
      return true if row[:active].blank?

      parsed_boolean(row[:active])
    end

    def parsed_boolean(value)
      case value.to_s.strip.downcase
      when "1", "true", "yes", "y", "active", "有効"
        true
      when "0", "false", "no", "n", "inactive", "無効"
        false
      end
    end

    def parsed_integer(value, default: nil, positive: false)
      return default if value.blank?

      integer = Integer(value.to_s, exception: false)
      return if integer.nil?
      return if positive && integer <= 0
      return if !positive && integer.negative?

      integer
    end

    def normalize_header(header)
      header.to_s.strip.downcase.tr(" ", "_")
    end

    def normalize_value(value)
      value.to_s.strip.presence
    end

    def streamed_xlsx_values(row)
      Array(row).map { |cell| cell.respond_to?(:value) ? cell.value : cell }
    end

    def path
      file.respond_to?(:path) ? file.path : file.to_s
    end

    def extension
      File.extname(file.respond_to?(:original_filename) ? file.original_filename : path).downcase
    end

    def content_type
      return unless file.respond_to?(:content_type)

      file.content_type.to_s
    end

    def file_size
      File.size(path)
    end

    def file_sample(bytes: SAMPLE_BYTES)
      File.binread(path, bytes)
    end

    def parse_errors
      [
        CSV::MalformedCSVError,
        Encoding::InvalidByteSequenceError,
        Encoding::UndefinedConversionError,
        Roo::FileNotFound,
        Zip::Error,
        ArgumentError
      ]
    end
  end
end
