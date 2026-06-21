class Submission < ApplicationRecord
  acts_as_paranoid

  MAX_FILE_SIZE = 20.megabytes
  ALLOWED_FILE_EXTENSIONS = %w[.docx .jpeg .jpg .md .pdf .png .pptx .txt .xlsx .zip].freeze

  enum :kind, {
    file: 0,
    github_repository: 1,
    supplement: 2
  }, default: :github_repository, validate: true

  belongs_to :review_application
  has_one_attached :file

  validates :title, presence: true, length: { maximum: 255 }
  validates :note, length: { maximum: 10_000 }
  validates :github_url, github_url: true, if: :github_repository?
  validate :github_url_required_for_repository
  validate :file_required_for_file_submission
  validate :file_size_within_limit
  validate :file_extension_is_allowed
  validate :review_application_is_editable

  def evidence?
    (github_repository? && github_url.present?) || (file? && file.attached?)
  end

  private

  def github_url_required_for_repository
    return unless github_repository?
    return if github_url.present?

    errors.add(:github_url, :required_for_github_repository_submission)
  end

  def file_required_for_file_submission
    return unless file?
    return if file.attached?

    errors.add(:file, :required_for_file_submission)
  end

  def file_size_within_limit
    return unless file?
    return unless file.attached?
    return if attached_file_byte_size <= MAX_FILE_SIZE

    errors.add(:file, :too_large_for_submission)
  end

  def file_extension_is_allowed
    return unless file?
    return unless file.attached?
    return if ALLOWED_FILE_EXTENSIONS.include?(attached_file_extension)

    errors.add(:file, :extension_not_allowed)
  end

  def review_application_is_editable
    return if review_application&.editable?

    errors.add(:review_application, :must_be_editable)
  end

  def attached_file_byte_size
    file.blob.byte_size
  end

  def attached_file_extension
    File.extname(file.filename.to_s).downcase
  end
end
