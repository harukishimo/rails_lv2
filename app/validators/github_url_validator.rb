class GithubUrlValidator < ActiveModel::EachValidator
  ALLOWED_HOSTS = %w[github.com www.github.com].freeze

  def validate_each(record, attribute, value)
    return if value.blank?

    uri = URI.parse(value)
    return if uri.is_a?(URI::HTTPS) &&
              ALLOWED_HOSTS.include?(uri.host&.downcase) &&
              uri.path.present? &&
              uri.path != "/" &&
              !value.to_s.match?(/\s/)

    record.errors.add(attribute, :github_url)
  rescue URI::InvalidURIError
    record.errors.add(attribute, :github_url)
  end
end
