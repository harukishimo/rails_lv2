class MarkdownRenderer
  ALLOWED_TAGS = %w[
    a blockquote br code del em h1 h2 h3 h4 h5 h6 hr li ol p pre strong table tbody td th thead tr ul
  ].freeze
  ALLOWED_ATTRIBUTES = %w[href title].freeze

  def self.call(markdown)
    new(markdown).call
  end

  def initialize(markdown)
    @markdown = markdown.to_s.encode("UTF-8", invalid: :replace, undef: :replace)
  end

  def call
    Rails::HTML5::SafeListSanitizer.new.sanitize(
      Commonmarker.to_html(markdown, options: commonmarker_options),
      tags: ALLOWED_TAGS,
      attributes: ALLOWED_ATTRIBUTES
    )
  end

  private

  attr_reader :markdown

  def commonmarker_options
    {
      parse: { smart: true },
      render: { unsafe: false }
    }
  end
end
