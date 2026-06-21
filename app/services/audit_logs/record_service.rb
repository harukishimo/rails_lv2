module AuditLogs
  class RecordService
    def self.call(action:, actor: nil, auditable: nil, ip_address: nil, user_agent: nil, before_changes: {}, after_changes: {})
      new(
        action: action,
        actor: actor,
        auditable: auditable,
        ip_address: ip_address,
        user_agent: user_agent,
        before_changes: before_changes,
        after_changes: after_changes
      ).call
    end

    def initialize(action:, actor:, auditable:, ip_address:, user_agent:, before_changes:, after_changes:)
      @action = action
      @actor = actor
      @auditable = auditable
      @ip_address = ip_address
      @user_agent = user_agent
      @before_changes = before_changes
      @after_changes = after_changes
    end

    def call
      AuditLog.create!(
        action: action,
        actor: actor,
        auditable: auditable,
        ip_address: ip_address,
        user_agent: user_agent,
        before_changes: redact(before_changes),
        after_changes: redact(after_changes),
        created_at: Time.current
      )
    rescue ActiveRecord::ActiveRecordError => error
      Rails.logger.error(
        {
          event: "audit_log.record_failed",
          action: action,
          error_class: error.class.name,
          error_message: Integrations::SecretRedactor.call(error.message)
        }.to_json
      )
      nil
    end

    private

    attr_reader :action, :actor, :auditable, :ip_address, :user_agent, :before_changes, :after_changes

    def redact(value)
      Integrations::SecretRedactor.call(value)
    end
  end
end
