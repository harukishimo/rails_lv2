module AuthorizationAuditLogging
  extend ActiveSupport::Concern

  private

  def log_authorization_denial(exception)
    payload = authorization_denial_payload(exception)
    record_authorization_audit_log(payload, exception)
    Rails.logger.warn(payload.to_json)
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

  def record_authorization_audit_log(payload, exception)
    return unless defined?(AuditLogs::RecordService)

    AuditLogs::RecordService.call(
      action: "authorization.denied",
      actor: authorization_audit_user,
      auditable: authorization_auditable(exception.record),
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      after_changes: payload
    )
  end

  def authorization_audit_user
    if respond_to?(:current_api_user, true)
      current_api_user
    elsif respond_to?(:current_user, true)
      current_user
    end
  end

  def authorization_auditable(record)
    record if record.is_a?(ApplicationRecord)
  end
end
