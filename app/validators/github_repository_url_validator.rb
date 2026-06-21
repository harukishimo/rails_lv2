class GithubRepositoryUrlValidator < ActiveModel::EachValidator
  REPOSITORY_PATH_PATTERN = %r{\A/[^/\s]+/[^/\s]+(?:\.git)?/?\z}

  def validate_each(record, attribute, value)
    return if value.blank?

    uri = URI.parse(value)
    return if uri.is_a?(URI::HTTPS) &&
              uri.host&.downcase == "github.com" &&
              uri.path.match?(REPOSITORY_PATH_PATTERN) &&
              uri.query.blank? &&
              uri.fragment.blank?

    record.errors.add(attribute, :github_repository_url)
  rescue URI::InvalidURIError
    record.errors.add(attribute, :github_repository_url)
  end
end
