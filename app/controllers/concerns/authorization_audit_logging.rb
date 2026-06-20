module AuthorizationAuditLogging
  extend ActiveSupport::Concern

  private

  def log_authorization_denial(exception)
    Rails.logger.warn(authorization_denial_payload(exception).to_json)
  end

  def authorization_denial_payload(exception)
    {
      event: "pundit.authorization_denied",
      request_id: request.request_id,
      user_id: authorization_audit_user_id,
      policy: exception.policy&.class&.name,
      query: exception.query,
      record: authorization_record_name(exception.record),
      controller: controller_path,
      action: action_name,
      path: request.path
    }
  end

  def authorization_audit_user_id
    if respond_to?(:current_api_user, true)
      current_api_user&.id
    elsif respond_to?(:current_user, true)
      current_user&.id
    end
  end

  def authorization_record_name(record)
    return if record.nil?

    record.is_a?(Symbol) ? record.to_s : record.class.name
  end
end
