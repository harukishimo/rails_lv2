# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

DEMO_PASSWORD = "password123" unless defined?(DEMO_PASSWORD)
DEMO_TARGET_VERSION = "2026.06" unless defined?(DEMO_TARGET_VERSION)

SKILL_AREA_DEFINITIONS = [
  { key: "backend", name: "バックエンド", display_order: 10, language_based: true },
  { key: "frontend", name: "フロントエンド", display_order: 20, language_based: true },
  { key: "test_qa", name: "試験・QA", display_order: 30, language_based: false },
  { key: "requirements", name: "要件定義", display_order: 50, language_based: false },
  { key: "cloud", name: "クラウド", display_order: 55, language_based: false },
  { key: "project_manager", name: "プロジェクトマネージャ", display_order: 60, language_based: false }
].freeze unless defined?(SKILL_AREA_DEFINITIONS)

LANGUAGE_DEFINITIONS = [
  { key: "ruby", name: "Ruby" },
  { key: "go", name: "Go" },
  { key: "php", name: "PHP" },
  { key: "java", name: "Java" },
  { key: "node", name: "Node" },
  { key: "next", name: "Next" },
  { key: "vue", name: "Vue" }
].freeze unless defined?(LANGUAGE_DEFINITIONS)

NO_LANGUAGE_DEFINITION = { key: "none", name: "言語なし" }.freeze unless defined?(NO_LANGUAGE_DEFINITION)

SKILL_LEVEL_DEFINITIONS = [
  { code: "Lv1", numeric_level: 1 },
  { code: "Lv2", numeric_level: 2 },
  { code: "Lv3", numeric_level: 3 }
].freeze unless defined?(SKILL_LEVEL_DEFINITIONS)

EVALUATION_PERIOD_DEFINITIONS = [
  { name: "2025 下期", starts_on: Date.new(2025, 10, 1), ends_on: Date.new(2026, 3, 31), active: false },
  { name: "2026 上期", starts_on: Date.new(2026, 4, 1), ends_on: Date.new(2026, 9, 30), active: true },
  { name: "2026 下期", starts_on: Date.new(2026, 10, 1), ends_on: Date.new(2027, 3, 31), active: true },
  { name: "2027 上期", starts_on: Date.new(2027, 4, 1), ends_on: Date.new(2027, 9, 30), active: true },
  { name: "2027 下期", starts_on: Date.new(2027, 10, 1), ends_on: Date.new(2028, 3, 31), active: true }
].freeze unless defined?(EVALUATION_PERIOD_DEFINITIONS)

FRAMEWORK_DEFINITIONS = [
  { key: "rails", name: "Ruby on Rails", language_key: "ruby" },
  { key: "spring_boot", name: "SpringBoot", language_key: "java" },
  { key: "nest", name: "Nest", language_key: "node" }
].freeze unless defined?(FRAMEWORK_DEFINITIONS)

EVALUATION_TARGET_DEFINITIONS = [
  {
    key: "backend_ruby",
    area_key: "backend",
    language_key: "ruby",
    level_codes: %w[Lv1 Lv2],
    version_suffix: "backend-ruby",
    external_key_prefix: "backend_ruby",
    display_order_offset: 10
  },
  {
    key: "ruby_rails",
    area_key: "backend",
    language_key: "ruby",
    framework_key: "rails",
    level_codes: %w[Lv2],
    version_suffix: "rails",
    external_key_prefix: "ruby_on_rails",
    external_key_overrides: { "Lv2" => "ruby_on_rails_lv2" },
    display_order_offset: 15
  },
  {
    key: "backend_go",
    area_key: "backend",
    language_key: "go",
    level_codes: %w[Lv1 Lv2],
    version_suffix: "backend-go",
    external_key_prefix: "backend_go",
    display_order_offset: 20
  },
  {
    key: "backend_php",
    area_key: "backend",
    language_key: "php",
    level_codes: %w[Lv1 Lv2],
    version_suffix: "backend-php",
    external_key_prefix: "backend_php",
    display_order_offset: 30
  },
  {
    key: "backend_java_spring",
    area_key: "backend",
    language_key: "java",
    framework_key: "spring_boot",
    level_codes: %w[Lv1 Lv2],
    version_suffix: "backend-java-spring",
    external_key_prefix: "backend_java_spring",
    display_order_offset: 40
  },
  {
    key: "backend_node_nest",
    area_key: "backend",
    language_key: "node",
    framework_key: "nest",
    level_codes: %w[Lv1 Lv2],
    version_suffix: "backend-node-nest",
    external_key_prefix: "backend_node_nest",
    display_order_offset: 50
  },
  {
    key: "frontend_next",
    area_key: "frontend",
    language_key: "next",
    level_codes: %w[Lv1 Lv2],
    version_suffix: "frontend-next",
    external_key_prefix: "frontend_next",
    display_order_offset: 10
  },
  {
    key: "frontend_vue",
    area_key: "frontend",
    language_key: "vue",
    level_codes: %w[Lv1 Lv2],
    version_suffix: "frontend-vue",
    external_key_prefix: "frontend_vue",
    display_order_offset: 20
  },
  {
    key: "requirements",
    area_key: "requirements",
    language_key: "none",
    level_codes: %w[Lv1 Lv2],
    version_suffix: "requirements",
    external_key_prefix: "requirements",
    display_order_offset: 10
  },
  {
    key: "test_qa",
    area_key: "test_qa",
    language_key: "none",
    level_codes: %w[Lv1 Lv2],
    version_suffix: "test-qa",
    external_key_prefix: "test_qa",
    display_order_offset: 10
  },
  {
    key: "cloud",
    area_key: "cloud",
    language_key: "none",
    level_codes: %w[Lv1 Lv2],
    version_suffix: "cloud",
    external_key_prefix: "cloud",
    display_order_offset: 10
  },
  {
    key: "project_manager",
    area_key: "project_manager",
    language_key: "none",
    level_codes: %w[Lv3],
    version_suffix: "project-manager",
    external_key_prefix: "project_manager",
    display_order_offset: 10
  }
].freeze unless defined?(EVALUATION_TARGET_DEFINITIONS)

def seed_record(model, lookup)
  relation = model.respond_to?(:with_deleted) ? model.with_deleted : model
  record = model.find_by(lookup) || relation.find_or_initialize_by(lookup)
  record.restore(recursive: false) if record.respond_to?(:deleted?) && record.deleted?
  yield record
  record.save!
  record
end

def seed_user(email:, name:, roles:)
  user = seed_record(User, email: email) do |record|
    record.name = name
    record.password = DEMO_PASSWORD
    record.password_confirmation = DEMO_PASSWORD
    record.active = true if record.respond_to?(:active=)
  end

  roles.each do |code|
    role = Role.find_by!(code: code)
    UserRole.find_or_create_by!(user: user, role: role)
  end

  user
end

def seed_examiner_profile(user:, display_name:, monthly_interview_count: 0, max_monthly_interviews: 10,
                          can_review: true, can_interview: true)
  seed_record(ExaminerProfile, user: user) do |record|
    record.display_name = display_name
    record.active = true
    record.can_review = can_review
    record.can_interview = can_interview
    record.monthly_interview_count = monthly_interview_count
    record.max_monthly_interviews = max_monthly_interviews
  end
end

def seed_examiner_capability(profile:, target:, can_review: true, can_interview: true)
  seed_record(ExaminerSkillCapability, examiner_profile: profile, evaluation_target: target) do |record|
    record.active = true
    record.can_review = can_review
    record.can_interview = can_interview
  end
end

def seed_github_submission(review_application:, title:, github_url:, note:)
  relation = Submission.respond_to?(:with_deleted) ? Submission.with_deleted : Submission
  record = Submission.find_by(review_application: review_application, title: title) ||
           relation.find_or_initialize_by(review_application: review_application, title: title)
  record.restore(recursive: false) if record.respond_to?(:deleted?) && record.deleted?
  return record if record.persisted? && !review_application.editable?

  record.kind = :github_repository
  record.github_url = github_url
  record.note = note
  record.save!
  record
end

def seed_exam_application(candidate:, evaluation_period:, evaluation_target:, attempt_number: 1, status: :declared,
                          result: :none, declared_at: Time.current, result_decided_at: nil, closed_at: nil)
  seed_record(
    ExamApplication,
    evaluation_period: evaluation_period,
    candidate: candidate,
    evaluation_target: evaluation_target,
    attempt_number: attempt_number
  ) do |record|
    record.status = status
    record.result = result
    record.declared_at = declared_at unless record.draft?
    record.result_decided_at = result_decided_at
    record.closed_at = closed_at
  end
end

def seed_historical_exam_application(candidate:, evaluation_period:, evaluation_target:, attempt_number: 1,
                                     result: :passed, declared_at:, result_decided_at:, closed_at:)
  relation = ExamApplication.respond_to?(:with_deleted) ? ExamApplication.with_deleted : ExamApplication
  record = ExamApplication.find_by(
    evaluation_period: evaluation_period,
    candidate: candidate,
    evaluation_target: evaluation_target,
    attempt_number: attempt_number
  ) || relation.find_or_initialize_by(
    evaluation_period: evaluation_period,
    candidate: candidate,
    evaluation_target: evaluation_target,
    attempt_number: attempt_number
  )
  record.restore(recursive: false) if record.respond_to?(:deleted?) && record.deleted?
  record.status = :closed
  record.result = result
  record.declared_at = declared_at
  record.result_decided_at = result_decided_at
  record.closed_at = closed_at
  record.save!(validate: false)
  record
end

def seed_submitted_review(exam_application:, actor:, appeal_markdown:, submission_title:, github_url:, note:)
  relation = ReviewApplication.respond_to?(:with_deleted) ? ReviewApplication.with_deleted : ReviewApplication
  existing = ReviewApplication.find_by(exam_application: exam_application, sequence_number: 1) ||
             relation.find_by(exam_application: exam_application, sequence_number: 1)
  if existing
    existing.restore(recursive: false) if existing.respond_to?(:deleted?) && existing.deleted?
    ExamApplications::TransitionService.new(exam_application, actor: actor).start_review! if
      existing.submitted? && exam_application.declared?
    return existing
  end

  ReviewApplications::CreateService.call(
    exam_application: exam_application,
    actor: actor,
    attributes: {
      appeal_markdown: appeal_markdown,
      submissions_attributes: {
        "0" => {
          kind: :github_repository,
          title: submission_title,
          github_url: github_url,
          note: note
        }
      }
    }
  )
end

def seed_draft_review(exam_application:, appeal_markdown:)
  seed_record(ReviewApplication, exam_application: exam_application, sequence_number: 1) do |record|
    record.status = :draft
    record.appeal_markdown = appeal_markdown
    record.submitted_at = nil
    record.canceled_at = nil
    record.cancel_reason = nil
    record.decided_at = nil
    record.decided_by = nil
  end
end

def seed_review_comment(review_application:, examiner:, body_markdown:)
  return review_application.review_comments.find_by(examiner: examiner, body_markdown: body_markdown) if
    review_application.review_comments.exists?(examiner: examiner, body_markdown: body_markdown)
  return unless review_application.commentable?

  ReviewComments::CreateService.call(
    review_application: review_application,
    examiner: examiner,
    attributes: { body_markdown: body_markdown }
  )
end

def seed_review_decision(review_application:, examiner:, decision:, reason_markdown: nil)
  existing = review_application.review_decisions.find_by(examiner: examiner, decision: decision)
  if existing
    ensure_review_decision_effects(review_application: review_application, examiner: examiner)
    return existing
  end
  return unless review_application.submitted?

  decision_record = ReviewDecisions::CreateService.call(
    review_application: review_application,
    examiner: examiner,
    attributes: {
      decision: decision,
      reason_markdown: reason_markdown
    }
  )
  ensure_review_decision_effects(review_application: review_application, examiner: examiner)
  decision_record
end

def ensure_review_decision_effects(review_application:, examiner:)
  exam_application = review_application.exam_application
  ExamApplications::TransitionService.new(exam_application, actor: examiner).start_review! if
    review_application.returned? && exam_application.declared?
  return unless review_application.approved?

  transition = ExamApplications::TransitionService.new(exam_application, actor: examiner)
  transition.start_review! if exam_application.declared?
  transition.approve_review! if exam_application.reviewing?
end

def seed_interview_application(exam_application:, actor:)
  relation = InterviewApplication.respond_to?(:with_deleted) ? InterviewApplication.with_deleted : InterviewApplication
  existing = InterviewApplication.find_by(exam_application: exam_application) ||
             relation.find_by(exam_application: exam_application)
  if existing
    existing.restore(recursive: false) if existing.respond_to?(:deleted?) && existing.deleted?
    return existing
  end
  exam_application.reload
  return unless exam_application.review_approved?

  InterviewApplications::CreateService.call(exam_application: exam_application, actor: actor)
end

def seed_assignment(interview_application:, actor:, examiner_profile:, secondary_examiner_profile: nil, reason: nil)
  return unless interview_application
  return interview_application if interview_application.assigned_examiner_profile_id == examiner_profile.id &&
                                  interview_application.secondary_assigned_examiner_profile_id == secondary_examiner_profile&.id
  return interview_application unless interview_application.assignable?

  InterviewApplications::AssignExaminerService.call(
    interview_application: interview_application,
    actor: actor,
    examiner_profile: examiner_profile,
    secondary_examiner_profile: secondary_examiner_profile,
    reason: reason
  )
end

def seed_interview_schedule(interview_application:, actor:, starts_at:, ends_at:)
  existing = interview_application.interview_schedules.order(:id).first
  return existing if existing
  return unless interview_application.schedulable?

  InterviewSchedules::CreateService.call(
    interview_application: interview_application,
    actor: actor,
    attributes: {
      starts_at: starts_at,
      ends_at: ends_at,
      timezone: InterviewSchedule::DEFAULT_TIMEZONE
    }
  )
end

def approve_interview_schedule(interview_schedule:, actor:)
  return interview_schedule unless interview_schedule&.requested?

  InterviewSchedules::ApproveService.call(interview_schedule: interview_schedule, actor: actor)
end

def mark_calendar_created(interview_application:, interview_schedule:, actor:)
  if interview_application.calendar_created?
    interview_application.exam_application.update!(status: :interview_scheduled) unless
      interview_application.exam_application.interview_scheduled?
    return interview_application
  end
  return interview_application unless interview_application.scheduled?

  previous_status = interview_application.status
  interview_schedule.update!(
    status: :calendar_created,
    google_calendar_event_id: "demo-calendar-#{interview_application.id}"
  )
  interview_application.update!(status: :calendar_created)
  StatusChangeEvents::RecordService.call(
    subject: interview_application,
    actor: actor,
    from_status: previous_status,
    to_status: "calendar_created",
    event_type: "interview_application_calendar_created",
    message: "Google Calendar event was created for the demo interview application",
    target_path: "/interview_applications/#{interview_application.id}",
    metadata: { exam_application_id: interview_application.exam_application_id }
  )
  interview_application
end

def seed_interview_result(interview_application:, examiner:, result:, comment_markdown:)
  return interview_application.interview_result if interview_application.interview_result.present?
  return unless interview_application.result_decidable?

  interview_application.exam_application.update!(status: :interview_scheduled) unless
    interview_application.exam_application.interview_scheduled?

  QualificationGrantService.call(
    interview_application: interview_application,
    examiner: examiner,
    attributes: {
      result: result,
      comment_markdown: comment_markdown
    }
  )
end

def seed_qualification(user:, evaluation_target:, exam_application:, acquired_on:, granted_by:)
  seed_record(UserQualification, user: user, evaluation_target: evaluation_target) do |record|
    record.exam_application = exam_application
    record.acquired_on = acquired_on
    record.granted_by = granted_by
    record.revoked_at = nil
  end
end

def seed_status_event(subject:, actor:, from_status:, to_status:, event_type:, message:)
  return if StatusChangeEvent.exists?(subject: subject, event_type: event_type, to_status: to_status)

  StatusChangeEvents::RecordService.call(
    subject: subject,
    actor: actor,
    from_status: from_status,
    to_status: to_status,
    event_type: event_type,
    message: message,
    target_path: subject.respond_to?(:to_model) ? "/#{subject.class.model_name.route_key}/#{subject.id}" : nil,
    metadata: {}
  )
end

if ActiveRecord::Base.connection.data_source_exists?("roles")
  Role::CODES.each do |code|
    Role.find_or_initialize_by(code: code).tap do |role|
      role.name = Role::NAMES.fetch(code)
      role.active = true
      role.save!
    end
  end
end

periods = {}
if ActiveRecord::Base.connection.data_source_exists?("evaluation_periods")
  EVALUATION_PERIOD_DEFINITIONS.each do |definition|
    periods[definition.fetch(:name)] = seed_record(EvaluationPeriod, name: definition.fetch(:name)) do |record|
      record.starts_on = definition.fetch(:starts_on)
      record.ends_on = definition.fetch(:ends_on)
      record.active = definition.fetch(:active)
    end
  end
  EvaluationPeriod.where.not(name: EVALUATION_PERIOD_DEFINITIONS.map { |definition| definition.fetch(:name) })
                  .update_all(active: false, updated_at: Time.current)
end

if %w[
  skill_areas
  programming_languages
  frameworks
  skill_levels
  evaluation_targets
].all? { |table_name| ActiveRecord::Base.connection.data_source_exists?(table_name) }
  skill_areas = SKILL_AREA_DEFINITIONS.index_with do |definition|
    seed_record(SkillArea, name: definition.fetch(:name)) do |record|
      record.display_order = definition.fetch(:display_order)
      record.active = true
    end
  end.transform_keys { |definition| definition.fetch(:key) }
  SkillArea.where.not(name: SKILL_AREA_DEFINITIONS.map { |definition| definition.fetch(:name) })
           .update_all(active: false, updated_at: Time.current)

  languages = (LANGUAGE_DEFINITIONS + [ NO_LANGUAGE_DEFINITION ]).index_with do |definition|
    seed_record(ProgrammingLanguage, name: definition.fetch(:name)) do |record|
      record.active = true
    end
  end.transform_keys { |definition| definition.fetch(:key) }
  ProgrammingLanguage.where.not(name: (LANGUAGE_DEFINITIONS + [ NO_LANGUAGE_DEFINITION ]).map { |definition| definition.fetch(:name) })
                     .update_all(active: false, updated_at: Time.current)

  levels = SKILL_LEVEL_DEFINITIONS.index_with do |definition|
    seed_record(SkillLevel, code: definition.fetch(:code)) do |record|
      record.numeric_level = definition.fetch(:numeric_level)
      record.active = true
    end
  end.transform_keys { |definition| definition.fetch(:code) }
  SkillLevel.where.not(code: SKILL_LEVEL_DEFINITIONS.map { |definition| definition.fetch(:code) })
            .update_all(active: false, updated_at: Time.current)

  frameworks = FRAMEWORK_DEFINITIONS.index_with do |definition|
    seed_record(Framework, name: definition.fetch(:name), programming_language: languages.fetch(definition.fetch(:language_key))) do |record|
      record.active = true
    end
  end.transform_keys { |definition| definition.fetch(:key) }
  Framework.where.not(name: FRAMEWORK_DEFINITIONS.map { |definition| definition.fetch(:name) })
           .update_all(active: false, updated_at: Time.current)

  targets = {}
  rails_target = nil
  EVALUATION_TARGET_DEFINITIONS.each do |target_definition|
    area_key = target_definition.fetch(:area_key)
    language_key = target_definition.fetch(:language_key)
    target_definition.fetch(:level_codes).each do |level_code|
      level = levels.fetch(level_code)
      framework_key = target_definition[:framework_key]
      framework = framework_key.present? ? frameworks.fetch(framework_key) : nil
      version = "#{DEMO_TARGET_VERSION}-#{target_definition.fetch(:version_suffix)}"
      external_key = target_definition.fetch(:external_key_overrides, {}).fetch(
        level_code,
        "#{target_definition.fetch(:external_key_prefix)}_#{level_code.downcase}"
      )
      target = seed_record(
        EvaluationTarget,
        programming_language: languages.fetch(language_key),
        framework: framework,
        skill_level: level,
        version: version
      ) do |record|
        record.skill_area = skill_areas.fetch(area_key)
        record.external_knowledge_key = external_key
        record.external_knowledge_url = "https://example.com/internal-knowledge/#{target_definition.fetch(:key)}/#{level_code.downcase}"
        record.description = [
          skill_areas.fetch(area_key).name,
          languages.fetch(language_key).name,
          framework&.name,
          level_code,
          "evaluation target. Criteria body is managed outside this app."
        ].compact.join(" ")
        record.display_order = (skill_areas.fetch(area_key).display_order * 100) +
                               target_definition.fetch(:display_order_offset) +
                               level.numeric_level
        record.active = true
      end

      targets[[ area_key, language_key, level_code ]] = target unless target_definition.fetch(:key) == "ruby_rails"
      rails_target = target if target_definition.fetch(:key) == "ruby_rails" && level_code == "Lv2"
    end
  end

  active_target_ids = (targets.values.map(&:id) + [ rails_target&.id ]).compact.uniq
  active_target_keys = EvaluationTarget.where(id: active_target_ids).pluck(:external_knowledge_key).compact
  EvaluationTarget.where.not(id: active_target_ids).find_each do |legacy_target|
    legacy_target.active = false
    if legacy_target.external_knowledge_key.present? && active_target_keys.include?(legacy_target.external_knowledge_key)
      legacy_target.external_knowledge_key = "legacy_#{legacy_target.id}_#{legacy_target.external_knowledge_key}"
    end
    legacy_target.save!(validate: false)
  end

  if Rails.configuration.x.local_demo_enabled && %w[
    users
    user_roles
    examiner_profiles
    examiner_skill_capabilities
    exam_applications
    review_applications
    submissions
    review_comments
    review_decisions
    interview_applications
    interview_schedules
    interview_results
    user_qualifications
    status_change_events
  ].all? { |table_name| ActiveRecord::Base.connection.data_source_exists?(table_name) }
    admin = seed_user(email: "admin@example.com", name: "管理者 太郎", roles: [ Role::ADMIN ])
    candidates = {
      main: seed_user(email: "candidate@example.com", name: "佐藤 候補", roles: [ Role::CANDIDATE ]),
      rails: seed_user(email: "candidate2@example.com", name: "鈴木 Rails", roles: [ Role::CANDIDATE ]),
      go: seed_user(email: "candidate3@example.com", name: "田中 Go", roles: [ Role::CANDIDATE ]),
      frontend: seed_user(email: "candidate4@example.com", name: "高橋 Frontend", roles: [ Role::CANDIDATE ]),
      qa: seed_user(email: "candidate5@example.com", name: "伊藤 QA", roles: [ Role::CANDIDATE ]),
      pm: seed_user(email: "candidate6@example.com", name: "山本 PM", roles: [ Role::CANDIDATE ]),
      retrying: seed_user(email: "candidate7@example.com", name: "中村 再受験", roles: [ Role::CANDIDATE ]),
      passed: seed_user(email: "candidate8@example.com", name: "小林 合格済", roles: [ Role::CANDIDATE ])
    }
    examiner_matrix = [
      {
        label: "バックエンド(Java/SpringBoot)",
        target_resolver: ->(level_code) { [ targets.fetch([ "backend", "java", level_code ]) ] },
        levels: {
          "Lv1" => %w[峰江 上甲],
          "Lv2" => %w[大川 峰江 大也]
        }
      },
      {
        label: "バックエンド(Ruby/Rails)",
        target_resolver: lambda { |level_code|
          resolved_targets = [ targets.fetch([ "backend", "ruby", level_code ]) ]
          resolved_targets << rails_target if level_code == "Lv2"
          resolved_targets
        },
        levels: {
          "Lv1" => %w[徳江 森田 小栗 前田 古謝],
          "Lv2" => %w[徳江 森田 小栗 前田 古謝]
        }
      },
      {
        label: "バックエンド(Golang)",
        target_resolver: ->(level_code) { [ targets.fetch([ "backend", "go", level_code ]) ] },
        levels: {
          "Lv1" => %w[峰江 中田 前田 小栗 藤井],
          "Lv2" => %w[峰江 中田 前田 小栗 藤井]
        }
      },
      {
        label: "バックエンド(node/Nest)",
        target_resolver: ->(level_code) { [ targets.fetch([ "backend", "node", level_code ]) ] },
        levels: {
          "Lv1" => %w[大山 藤井 徳江 森田],
          "Lv2" => %w[大山 藤井 徳江 森田]
        }
      },
      {
        label: "バックエンド(PHP)",
        target_resolver: ->(level_code) { [ targets.fetch([ "backend", "php", level_code ]) ] },
        levels: {
          "Lv1" => %w[徳江 古謝 山下 湊],
          "Lv2" => %w[徳江 古謝]
        }
      },
      {
        label: "フロントエンド(React/Next)",
        target_resolver: ->(level_code) { [ targets.fetch([ "frontend", "next", level_code ]) ] },
        levels: {
          "Lv1" => %w[上竹 山崎 太郎 航平],
          "Lv2" => %w[上竹 山崎 太郎 航平]
        }
      },
      {
        label: "フロントエンド(Vue/Nuxt)",
        target_resolver: ->(level_code) { [ targets.fetch([ "frontend", "vue", level_code ]) ] },
        levels: {
          "Lv1" => %w[上竹 太郎 航平],
          "Lv2" => %w[上竹 太郎 航平]
        }
      },
      {
        label: "システム要件定義・設計",
        target_resolver: ->(level_code) { [ targets.fetch([ "requirements", "none", level_code ]) ] },
        levels: {
          "Lv1" => %w[江頭 森本 峰江 中田],
          "Lv2" => %w[江頭 森本 峰江 中田]
        }
      },
      {
        label: "試験・QA",
        target_resolver: ->(level_code) { [ targets.fetch([ "test_qa", "none", level_code ]) ] },
        levels: {
          "Lv1" => %w[裕 江頭 省木 山下],
          "Lv2" => %w[裕 省木]
        }
      },
      {
        label: "クラウド",
        target_resolver: ->(level_code) { [ targets.fetch([ "cloud", "none", level_code ]) ] },
        levels: {
          "Lv1" => %w[田中 濱野 田畑],
          "Lv2" => %w[田中 濱野 田畑]
        }
      },
      {
        label: "プロジェクトマネージャー",
        target_resolver: ->(level_code) { [ targets.fetch([ "project_manager", "none", level_code ]) ] },
        levels: {
          "Lv3" => %w[道畑 平塚]
        }
      }
    ]

    preferred_examiner_names = %w[徳江 森田 峰江 江頭 上竹 田中 道畑]
    matrix_examiner_names = examiner_matrix.flat_map { |definition| definition.fetch(:levels).values }.flatten
    ordered_examiner_names = (preferred_examiner_names + matrix_examiner_names).uniq
    examiners_by_name = {}
    examiner_profiles_by_name = {}

    ordered_examiner_names.each.with_index(1) do |name, index|
      email = index == 1 ? "examiner@example.com" : "examiner#{index}@example.com"
      user = seed_user(email: email, name: name, roles: [ Role::EXAMINER ])
      examiners_by_name[name] = user
      examiner_profiles_by_name[name] = seed_examiner_profile(
        user: user,
        display_name: name,
        monthly_interview_count: index % 4,
        max_monthly_interviews: 8
      )
    end

    desired_capability_ids = []
    examiner_matrix.each do |definition|
      definition.fetch(:levels).each do |level_code, names|
        definition.fetch(:target_resolver).call(level_code).each do |target|
          names.each do |name|
            capability = seed_examiner_capability(profile: examiner_profiles_by_name.fetch(name), target: target)
            desired_capability_ids << capability.id
          end
        end
      end
    end
    ExaminerSkillCapability.where(examiner_profile_id: examiner_profiles_by_name.values.map(&:id))
                           .where.not(id: desired_capability_ids)
                           .update_all(active: false, can_review: false, can_interview: false, updated_at: Time.current)

    examiners = {
      primary: examiners_by_name.fetch("徳江"),
      backup: examiners_by_name.fetch("森田"),
      go: examiners_by_name.fetch("峰江"),
      frontend: examiners_by_name.fetch("上竹"),
      cloud: examiners_by_name.fetch("田中"),
      no_language: examiners_by_name.fetch("江頭"),
      qa: examiners_by_name.fetch("裕"),
      pm: examiners_by_name.fetch("道畑")
    }
    primary_profile = examiner_profiles_by_name.fetch("徳江")
    backup_profile = examiner_profiles_by_name.fetch("森田")
    go_profile = examiner_profiles_by_name.fetch("峰江")
    frontend_profile = examiner_profiles_by_name.fetch("上竹")
    cloud_profile = examiner_profiles_by_name.fetch("田中")
    no_language_profile = examiner_profiles_by_name.fetch("江頭")
    pm_profile = examiner_profiles_by_name.fetch("道畑")

    current_period = periods.fetch("2026 上期")
    past_period = periods.fetch("2025 下期")
    now = Time.current

    submitted_exam = seed_exam_application(
      candidate: candidates.fetch(:main),
      evaluation_period: current_period,
      evaluation_target: rails_target
    )
    submitted_review = seed_submitted_review(
      exam_application: submitted_exam,
      actor: candidates.fetch(:main),
      appeal_markdown: "## Rails Lv2 提出\n\nレビューと面談の両方で確認できるようにしています。",
      submission_title: "SkillEvidenceHub Rails demo repository",
      github_url: "https://github.com/harukishimo/rails_lv2",
      note: "Rails Lv2 evaluation demo repository."
    )
    seed_review_comment(
      review_application: submitted_review,
      examiner: examiners.fetch(:primary),
      body_markdown: "提出内容を確認中です。設計意図とテスト方針を重点確認します。"
    )

    requested_exam = seed_exam_application(
      candidate: candidates.fetch(:main),
      evaluation_period: current_period,
      evaluation_target: targets.fetch([ "backend", "ruby", "Lv1" ])
    )
    requested_review = seed_submitted_review(
      exam_application: requested_exam,
      actor: candidates.fetch(:main),
      appeal_markdown: "## Ruby/Rails Lv1 提出\n\nレビュー承認後、面談応募のみ完了しているデモです。",
      submission_title: "Ruby Rails requested interview evidence",
      github_url: "https://github.com/harukishimo/ruby_rails_lv1_demo",
      note: "Requested interview scenario."
    )
    seed_review_decision(
      review_application: requested_review,
      examiner: examiners.fetch(:primary),
      decision: :approve
    )
    seed_interview_application(exam_application: requested_exam, actor: candidates.fetch(:main))

    approved_exam = seed_exam_application(
      candidate: candidates.fetch(:rails),
      evaluation_period: current_period,
      evaluation_target: rails_target
    )
    approved_review = seed_submitted_review(
      exam_application: approved_exam,
      actor: candidates.fetch(:rails),
      appeal_markdown: "## Rails 実装証跡\n\n認証、認可、Ridgepole、テストをまとめて提出します。",
      submission_title: "Rails approved review repository",
      github_url: "https://github.com/harukishimo/rails_lv2_review_approved",
      note: "Approved review scenario."
    )
    seed_review_comment(
      review_application: approved_review,
      examiner: examiners.fetch(:primary),
      body_markdown: "レビュー基準を満たしているため承認します。"
    )
    seed_review_decision(
      review_application: approved_review,
      examiner: examiners.fetch(:primary),
      decision: :approve
    )
    assigned_interview = seed_interview_application(exam_application: approved_exam, actor: candidates.fetch(:rails))
    seed_assignment(
      interview_application: assigned_interview,
      actor: admin,
      examiner_profile: backup_profile,
      secondary_examiner_profile: examiner_profiles_by_name.fetch("小栗"),
      reason: "デモ用にRuby/Rails評価官へ手動割り当て"
    )

    returned_exam = seed_exam_application(
      candidate: candidates.fetch(:go),
      evaluation_period: current_period,
      evaluation_target: targets.fetch([ "backend", "go", "Lv2" ])
    )
    returned_review = seed_submitted_review(
      exam_application: returned_exam,
      actor: candidates.fetch(:go),
      appeal_markdown: "## Go Lv2 提出\n\n並行処理とエラーハンドリングの証跡を提出します。",
      submission_title: "Go returned review repository",
      github_url: "https://github.com/harukishimo/go_lv3_demo",
      note: "Returned review scenario."
    )
    seed_review_comment(
      review_application: returned_review,
      examiner: examiners.fetch(:go),
      body_markdown: "並行処理のテストケースが不足しています。追加してください。"
    )
    seed_review_decision(
      review_application: returned_review,
      examiner: examiners.fetch(:go),
      decision: :return_to_candidate,
      reason_markdown: "排他制御と異常系テストの証跡を追加してください。"
    )

    rejected_exam = seed_exam_application(
      candidate: candidates.fetch(:frontend),
      evaluation_period: current_period,
      evaluation_target: targets.fetch([ "frontend", "next", "Lv2" ])
    )
    rejected_review = seed_submitted_review(
      exam_application: rejected_exam,
      actor: candidates.fetch(:frontend),
      appeal_markdown: "## Next Lv2 提出\n\n画面実装を中心に提出します。",
      submission_title: "Next rejected review repository",
      github_url: "https://github.com/harukishimo/next_lv2_demo",
      note: "Rejected review scenario."
    )
    seed_review_comment(
      review_application: rejected_review,
      examiner: examiners.fetch(:frontend),
      body_markdown: "状態管理とアクセシビリティ要件の説明が不足しています。"
    )
    seed_review_decision(
      review_application: rejected_review,
      examiner: examiners.fetch(:frontend),
      decision: :reject,
      reason_markdown: "必須要件の証跡が不足しているため却下します。"
    )

    draft_exam = seed_exam_application(
      candidate: candidates.fetch(:qa),
      evaluation_period: current_period,
      evaluation_target: targets.fetch([ "test_qa", "none", "Lv1" ])
    )
    seed_draft_review(
      exam_application: draft_exam,
      appeal_markdown: "## Test & QA Lv1 下書き\n\nテスト設計観点を整理中です。"
    )

    schedule_requested_exam = seed_exam_application(
      candidate: candidates.fetch(:pm),
      evaluation_period: current_period,
      evaluation_target: targets.fetch([ "project_manager", "none", "Lv3" ])
    )
    schedule_review = seed_submitted_review(
      exam_application: schedule_requested_exam,
      actor: candidates.fetch(:pm),
      appeal_markdown: "## PM Lv3 提出\n\n計画、リスク管理、ステークホルダー調整の証跡です。",
      submission_title: "Project manager approved review evidence",
      github_url: "https://github.com/harukishimo/pm_lv3_demo",
      note: "Schedule requested interview scenario."
    )
    seed_review_decision(review_application: schedule_review, examiner: examiners.fetch(:pm), decision: :approve)
    schedule_requested_interview = seed_interview_application(
      exam_application: schedule_requested_exam,
      actor: candidates.fetch(:pm)
    )
    seed_assignment(
      interview_application: schedule_requested_interview,
      actor: admin,
      examiner_profile: pm_profile,
      secondary_examiner_profile: examiner_profiles_by_name.fetch("平塚"),
      reason: "PM領域の評価官へ割り当て"
    )
    seed_interview_schedule(
      interview_application: schedule_requested_interview,
      actor: candidates.fetch(:pm),
      starts_at: 10.days.from_now.change(hour: 14, min: 0, sec: 0),
      ends_at: 10.days.from_now.change(hour: 15, min: 0, sec: 0)
    )

    failed_retry_exam = seed_exam_application(
      candidate: candidates.fetch(:retrying),
      evaluation_period: current_period,
      evaluation_target: targets.fetch([ "cloud", "none", "Lv2" ]),
      attempt_number: 1,
      status: :closed,
      result: :failed,
      declared_at: 45.days.ago,
      result_decided_at: 30.days.ago,
      closed_at: 30.days.ago
    )
    seed_status_event(
      subject: failed_retry_exam,
      actor: examiners.fetch(:cloud),
      from_status: "interview_scheduled",
      to_status: "closed",
      event_type: "exam_application_failed_closed",
      message: "First attempt was failed and closed for retry demo."
    )
    retry_exam = seed_exam_application(
      candidate: candidates.fetch(:retrying),
      evaluation_period: current_period,
      evaluation_target: targets.fetch([ "cloud", "none", "Lv2" ]),
      attempt_number: 2
    )
    retry_review = seed_submitted_review(
      exam_application: retry_exam,
      actor: candidates.fetch(:retrying),
      appeal_markdown: "## クラウド Lv2 再受験\n\n前回指摘された例外処理と運用設計を改善しました。",
      submission_title: "Cloud retry approved evidence",
      github_url: "https://github.com/harukishimo/cloud_retry",
      note: "Retry scheduled interview scenario."
    )
    seed_review_decision(review_application: retry_review, examiner: examiners.fetch(:cloud), decision: :approve)
    scheduled_interview = seed_interview_application(exam_application: retry_exam, actor: candidates.fetch(:retrying))
    seed_assignment(
      interview_application: scheduled_interview,
      actor: admin,
      examiner_profile: cloud_profile,
      secondary_examiner_profile: examiner_profiles_by_name.fetch("濱野"),
      reason: "クラウド評価官へ割り当て"
    )
    approved_schedule = seed_interview_schedule(
      interview_application: scheduled_interview,
      actor: candidates.fetch(:retrying),
      starts_at: 12.days.from_now.change(hour: 11, min: 0, sec: 0),
      ends_at: 12.days.from_now.change(hour: 12, min: 0, sec: 0)
    )
    approve_interview_schedule(interview_schedule: approved_schedule, actor: examiners.fetch(:cloud))

    calendar_exam = seed_exam_application(
      candidate: candidates.fetch(:passed),
      evaluation_period: current_period,
      evaluation_target: targets.fetch([ "frontend", "vue", "Lv2" ])
    )
    calendar_review = seed_submitted_review(
      exam_application: calendar_exam,
      actor: candidates.fetch(:passed),
      appeal_markdown: "## Vue Lv2 提出\n\n大規模画面設計とレビュー証跡を提出します。",
      submission_title: "Vue calendar created evidence",
      github_url: "https://github.com/harukishimo/vue_lv3_demo",
      note: "Calendar created interview scenario."
    )
    seed_review_decision(review_application: calendar_review, examiner: examiners.fetch(:frontend), decision: :approve)
    calendar_interview = seed_interview_application(exam_application: calendar_exam, actor: candidates.fetch(:passed))
    seed_assignment(
      interview_application: calendar_interview,
      actor: admin,
      examiner_profile: frontend_profile,
      secondary_examiner_profile: examiner_profiles_by_name.fetch("太郎"),
      reason: "Vue対応可能な評価官へ割り当て"
    )
    calendar_schedule = seed_interview_schedule(
      interview_application: calendar_interview,
      actor: candidates.fetch(:passed),
      starts_at: 15.days.from_now.change(hour: 16, min: 0, sec: 0),
      ends_at: 15.days.from_now.change(hour: 17, min: 0, sec: 0)
    )
    approve_interview_schedule(interview_schedule: calendar_schedule, actor: examiners.fetch(:frontend))
    mark_calendar_created(
      interview_application: calendar_interview,
      interview_schedule: calendar_schedule,
      actor: examiners.fetch(:frontend)
    )

    completed_exam = seed_exam_application(
      candidate: candidates.fetch(:passed),
      evaluation_period: current_period,
      evaluation_target: targets.fetch([ "requirements", "none", "Lv2" ])
    )
    completed_review = seed_submitted_review(
      exam_application: completed_exam,
      actor: candidates.fetch(:passed),
      appeal_markdown: "## 要件定義 Lv2 提出\n\n業務要件、機能要件、受け入れ条件の証跡です。",
      submission_title: "Requirements passed evidence",
      github_url: "https://github.com/harukishimo/requirements_lv2_demo",
      note: "Completed passed interview scenario."
    )
    seed_review_decision(review_application: completed_review, examiner: examiners.fetch(:no_language), decision: :approve)
    completed_interview = seed_interview_application(exam_application: completed_exam, actor: candidates.fetch(:passed))
    seed_assignment(
      interview_application: completed_interview,
      actor: admin,
      examiner_profile: no_language_profile,
      secondary_examiner_profile: examiner_profiles_by_name.fetch("森本"),
      reason: "要件定義評価官へ割り当て"
    )
    completed_schedule = seed_interview_schedule(
      interview_application: completed_interview,
      actor: candidates.fetch(:passed),
      starts_at: 18.days.from_now.change(hour: 10, min: 0, sec: 0),
      ends_at: 18.days.from_now.change(hour: 11, min: 0, sec: 0)
    )
    approve_interview_schedule(interview_schedule: completed_schedule, actor: examiners.fetch(:no_language))
    mark_calendar_created(
      interview_application: completed_interview,
      interview_schedule: completed_schedule,
      actor: examiners.fetch(:no_language)
    )
    seed_interview_result(
      interview_application: completed_interview,
      examiner: examiners.fetch(:no_language),
      result: :passed,
      comment_markdown: "要件の粒度、受け入れ条件、レビュー観点が十分に整理されています。"
    )

    past_exam = seed_historical_exam_application(
      candidate: candidates.fetch(:passed),
      evaluation_period: past_period,
      evaluation_target: targets.fetch([ "backend", "php", "Lv1" ]),
      attempt_number: 1,
      result: :passed,
      declared_at: Time.zone.local(2026, 1, 10, 10, 0, 0),
      result_decided_at: Time.zone.local(2026, 2, 5, 17, 0, 0),
      closed_at: Time.zone.local(2026, 2, 5, 17, 30, 0)
    )
    seed_qualification(
      user: candidates.fetch(:passed),
      evaluation_target: targets.fetch([ "backend", "php", "Lv1" ]),
      exam_application: past_exam,
      acquired_on: Date.new(2026, 2, 5),
      granted_by: examiners.fetch(:primary)
    )
    seed_status_event(
      subject: past_exam,
      actor: examiners.fetch(:primary),
      from_status: "interview_scheduled",
      to_status: "closed",
      event_type: "exam_application_past_passed_closed",
      message: "Past passed application from 2025 下期."
    )

    canceled_exam = seed_exam_application(
      candidate: candidates.fetch(:rails),
      evaluation_period: current_period,
      evaluation_target: targets.fetch([ "requirements", "none", "Lv1" ])
    )
    canceled_review = seed_submitted_review(
      exam_application: canceled_exam,
      actor: candidates.fetch(:rails),
      appeal_markdown: "## 要件定義 Lv1 取り消しデモ\n\n提出後に受験者都合で取り消します。",
      submission_title: "Requirements canceled review evidence",
      github_url: "https://github.com/harukishimo/requirements_lv1_canceled",
      note: "Canceled review scenario."
    )
    ReviewApplications::CancelService.call(
      review_application: canceled_review,
      actor: candidates.fetch(:rails),
      cancel_reason: "デモ用の取り消しデータ"
    ) if canceled_review.cancelable?

    primary_profile.update!(monthly_interview_count: 2)
    backup_profile.update!(monthly_interview_count: 1)
    go_profile.update!(monthly_interview_count: 3)
    cloud_profile.update!(monthly_interview_count: 4)
    frontend_profile.update!(monthly_interview_count: 2)
    no_language_profile.update!(monthly_interview_count: 7)
    pm_profile.update!(monthly_interview_count: 1)

    unless Rails.env.test?
      puts "Demo accounts:"
      puts "  admin@example.com / #{DEMO_PASSWORD}"
      puts "  candidate@example.com - candidate8@example.com / #{DEMO_PASSWORD}"
      puts "  examiner@example.com - examiner#{ordered_examiner_names.size}@example.com / #{DEMO_PASSWORD}"
      puts "Demo master records: #{SkillArea.active.count} active skill areas, #{ProgrammingLanguage.active.count} active languages, #{EvaluationTarget.active.count} active evaluation targets"
      puts "Demo workflow records: #{ExamApplication.count} exams, #{ReviewApplication.count} reviews, #{InterviewApplication.count} interviews"
    end
  end
end
