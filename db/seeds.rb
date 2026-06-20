# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

DEMO_PASSWORD = "password123" unless defined?(DEMO_PASSWORD)
DEMO_TARGET_VERSION = "2026.06" unless defined?(DEMO_TARGET_VERSION)

SKILL_AREA_DEFINITIONS = [
  { key: "frontend", name: "Front End", display_order: 10, language_based: true },
  { key: "infra", name: "Infra", display_order: 20, language_based: true },
  { key: "test_qa", name: "Test & QA", display_order: 30, language_based: false },
  { key: "design", name: "Design", display_order: 40, language_based: false },
  { key: "requirements", name: "要件定義", display_order: 50, language_based: false },
  { key: "project_manager", name: "プロジェクトマネージャ", display_order: 60, language_based: false }
].freeze unless defined?(SKILL_AREA_DEFINITIONS)

LANGUAGE_DEFINITIONS = [
  { key: "ruby", name: "Ruby" },
  { key: "go", name: "Go" },
  { key: "php", name: "PHP" },
  { key: "python", name: "Python" },
  { key: "java", name: "Java" },
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

  InterviewApplications::CreateService.call(exam_application: exam_application, actor: actor)
end

def seed_assignment(interview_application:, actor:, examiner_profile:, reason: nil)
  return interview_application if interview_application.assigned_examiner_profile_id == examiner_profile.id
  return interview_application unless interview_application.assignable?

  InterviewApplications::AssignExaminerService.call(
    interview_application: interview_application,
    actor: actor,
    examiner_profile: examiner_profile,
    reason: reason
  )
end

def seed_interview_schedule(interview_application:, actor:, starts_at:, ends_at:)
  existing = interview_application.interview_schedules.find_by(starts_at: starts_at, ends_at: ends_at)
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

  rails_framework = seed_record(Framework, name: "Ruby on Rails", programming_language: languages.fetch("ruby")) do |record|
    record.active = true
  end

  targets = {}
  SKILL_AREA_DEFINITIONS.each do |area_definition|
    language_definitions = area_definition.fetch(:language_based) ? LANGUAGE_DEFINITIONS : [ NO_LANGUAGE_DEFINITION ]
    language_definitions.each do |language_definition|
      SKILL_LEVEL_DEFINITIONS.each do |level_definition|
        area_key = area_definition.fetch(:key)
        language_key = language_definition.fetch(:key)
        level_code = level_definition.fetch(:code)
        version = "#{DEMO_TARGET_VERSION}-#{area_key}"
        targets[[ area_key, language_key, level_code ]] = seed_record(
          EvaluationTarget,
          programming_language: languages.fetch(language_key),
          framework: nil,
          skill_level: levels.fetch(level_code),
          version: version
        ) do |record|
          record.skill_area = skill_areas.fetch(area_key)
          record.external_knowledge_key = "#{area_key}_#{language_key}_#{level_code.downcase}"
          record.external_knowledge_url = "https://example.com/internal-knowledge/#{area_key}/#{language_key}/#{level_code.downcase}"
          record.description = "#{area_definition.fetch(:name)} #{language_definition.fetch(:name)} #{level_code} evaluation target."
          record.display_order = area_definition.fetch(:display_order) + level_definition.fetch(:numeric_level)
          record.active = true
        end
      end
    end
  end

  rails_target = seed_record(
    EvaluationTarget,
    programming_language: languages.fetch("ruby"),
    framework: rails_framework,
    skill_level: levels.fetch("Lv2"),
    version: "#{DEMO_TARGET_VERSION}-rails"
  ) do |record|
    record.skill_area = skill_areas.fetch("frontend")
    record.external_knowledge_key = "ruby_on_rails_lv2"
    record.external_knowledge_url = "https://example.com/internal-knowledge/ruby-on-rails/lv2"
    record.description = "Ruby on Rails Lv2 evaluation target. Criteria body is managed outside this app."
    record.display_order = 15
    record.active = true
  end
  active_target_ids = targets.values.map(&:id) + [ rails_target.id ]
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
    examiners = {
      primary: seed_user(email: "examiner@example.com", name: "評価官 Rails", roles: [ Role::EXAMINER ]),
      backup: seed_user(email: "examiner2@example.com", name: "評価官 Backup", roles: [ Role::EXAMINER ]),
      infra: seed_user(email: "examiner3@example.com", name: "評価官 Infra", roles: [ Role::EXAMINER ]),
      no_language: seed_user(email: "examiner4@example.com", name: "評価官 NonCoding", roles: [ Role::EXAMINER ])
    }

    primary_profile = seed_examiner_profile(
      user: examiners.fetch(:primary),
      display_name: "評価官 Rails",
      monthly_interview_count: 1,
      max_monthly_interviews: 8
    )
    backup_profile = seed_examiner_profile(
      user: examiners.fetch(:backup),
      display_name: "評価官 Backup",
      monthly_interview_count: 0,
      max_monthly_interviews: 8
    )
    infra_profile = seed_examiner_profile(
      user: examiners.fetch(:infra),
      display_name: "評価官 Infra",
      monthly_interview_count: 4,
      max_monthly_interviews: 8
    )
    no_language_profile = seed_examiner_profile(
      user: examiners.fetch(:no_language),
      display_name: "評価官 NonCoding",
      monthly_interview_count: 5,
      max_monthly_interviews: 10
    )

    ([ rails_target ] + targets.values).each do |target|
      seed_examiner_capability(profile: primary_profile, target: target)
    end
    [ rails_target, targets.fetch([ "frontend", "ruby", "Lv2" ]), targets.fetch([ "infra", "go", "Lv3" ]) ].each do |target|
      seed_examiner_capability(profile: backup_profile, target: target)
    end
    targets.select { |(area_key, _language_key, _level), _target| area_key == "infra" }.each_value do |target|
      seed_examiner_capability(profile: infra_profile, target: target)
    end
    targets.select { |(area_key, _language_key, _level), _target|
      %w[test_qa design requirements project_manager].include?(area_key)
    }.each_value do |target|
      seed_examiner_capability(profile: no_language_profile, target: target)
    end

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
    seed_interview_application(exam_application: submitted_exam, actor: candidates.fetch(:main))

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
      reason: "デモ用にBackup評価官へ手動割り当て"
    )

    returned_exam = seed_exam_application(
      candidate: candidates.fetch(:go),
      evaluation_period: current_period,
      evaluation_target: targets.fetch([ "infra", "go", "Lv3" ])
    )
    returned_review = seed_submitted_review(
      exam_application: returned_exam,
      actor: candidates.fetch(:go),
      appeal_markdown: "## Go Lv3 提出\n\n並行処理とエラーハンドリングの証跡を提出します。",
      submission_title: "Go returned review repository",
      github_url: "https://github.com/harukishimo/go_lv3_demo",
      note: "Returned review scenario."
    )
    seed_review_comment(
      review_application: returned_review,
      examiner: examiners.fetch(:infra),
      body_markdown: "並行処理のテストケースが不足しています。追加してください。"
    )
    seed_review_decision(
      review_application: returned_review,
      examiner: examiners.fetch(:infra),
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
      examiner: examiners.fetch(:primary),
      body_markdown: "状態管理とアクセシビリティ要件の説明が不足しています。"
    )
    seed_review_decision(
      review_application: rejected_review,
      examiner: examiners.fetch(:primary),
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
    seed_review_decision(review_application: schedule_review, examiner: examiners.fetch(:no_language), decision: :approve)
    schedule_requested_interview = seed_interview_application(
      exam_application: schedule_requested_exam,
      actor: candidates.fetch(:pm)
    )
    seed_assignment(
      interview_application: schedule_requested_interview,
      actor: admin,
      examiner_profile: no_language_profile,
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
      evaluation_target: targets.fetch([ "infra", "python", "Lv2" ]),
      attempt_number: 1,
      status: :closed,
      result: :failed,
      declared_at: 45.days.ago,
      result_decided_at: 30.days.ago,
      closed_at: 30.days.ago
    )
    seed_status_event(
      subject: failed_retry_exam,
      actor: examiners.fetch(:infra),
      from_status: "interview_scheduled",
      to_status: "closed",
      event_type: "exam_application_failed_closed",
      message: "First attempt was failed and closed for retry demo."
    )
    retry_exam = seed_exam_application(
      candidate: candidates.fetch(:retrying),
      evaluation_period: current_period,
      evaluation_target: targets.fetch([ "infra", "python", "Lv2" ]),
      attempt_number: 2
    )
    retry_review = seed_submitted_review(
      exam_application: retry_exam,
      actor: candidates.fetch(:retrying),
      appeal_markdown: "## Python Infra Lv2 再受験\n\n前回指摘された例外処理と運用設計を改善しました。",
      submission_title: "Python retry approved evidence",
      github_url: "https://github.com/harukishimo/python_infra_retry",
      note: "Retry scheduled interview scenario."
    )
    seed_review_decision(review_application: retry_review, examiner: examiners.fetch(:infra), decision: :approve)
    scheduled_interview = seed_interview_application(exam_application: retry_exam, actor: candidates.fetch(:retrying))
    seed_assignment(
      interview_application: scheduled_interview,
      actor: admin,
      examiner_profile: infra_profile,
      reason: "Infra評価官へ割り当て"
    )
    approved_schedule = seed_interview_schedule(
      interview_application: scheduled_interview,
      actor: candidates.fetch(:retrying),
      starts_at: 12.days.from_now.change(hour: 11, min: 0, sec: 0),
      ends_at: 12.days.from_now.change(hour: 12, min: 0, sec: 0)
    )
    approve_interview_schedule(interview_schedule: approved_schedule, actor: examiners.fetch(:infra))

    calendar_exam = seed_exam_application(
      candidate: candidates.fetch(:passed),
      evaluation_period: current_period,
      evaluation_target: targets.fetch([ "frontend", "vue", "Lv3" ])
    )
    calendar_review = seed_submitted_review(
      exam_application: calendar_exam,
      actor: candidates.fetch(:passed),
      appeal_markdown: "## Vue Lv3 提出\n\n大規模画面設計とレビュー証跡を提出します。",
      submission_title: "Vue calendar created evidence",
      github_url: "https://github.com/harukishimo/vue_lv3_demo",
      note: "Calendar created interview scenario."
    )
    seed_review_decision(review_application: calendar_review, examiner: examiners.fetch(:primary), decision: :approve)
    calendar_interview = seed_interview_application(exam_application: calendar_exam, actor: candidates.fetch(:passed))
    seed_assignment(
      interview_application: calendar_interview,
      actor: admin,
      examiner_profile: primary_profile,
      reason: "Vue対応可能な評価官へ割り当て"
    )
    calendar_schedule = seed_interview_schedule(
      interview_application: calendar_interview,
      actor: candidates.fetch(:passed),
      starts_at: 15.days.from_now.change(hour: 16, min: 0, sec: 0),
      ends_at: 15.days.from_now.change(hour: 17, min: 0, sec: 0)
    )
    approve_interview_schedule(interview_schedule: calendar_schedule, actor: examiners.fetch(:primary))
    mark_calendar_created(
      interview_application: calendar_interview,
      interview_schedule: calendar_schedule,
      actor: examiners.fetch(:primary)
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
      evaluation_target: targets.fetch([ "frontend", "php", "Lv1" ]),
      attempt_number: 1,
      result: :passed,
      declared_at: Time.zone.local(2026, 1, 10, 10, 0, 0),
      result_decided_at: Time.zone.local(2026, 2, 5, 17, 0, 0),
      closed_at: Time.zone.local(2026, 2, 5, 17, 30, 0)
    )
    seed_qualification(
      user: candidates.fetch(:passed),
      evaluation_target: targets.fetch([ "frontend", "php", "Lv1" ]),
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
      evaluation_target: targets.fetch([ "design", "none", "Lv1" ])
    )
    canceled_review = seed_submitted_review(
      exam_application: canceled_exam,
      actor: candidates.fetch(:rails),
      appeal_markdown: "## Design Lv1 取り消しデモ\n\n提出後に受験者都合で取り消します。",
      submission_title: "Design canceled review evidence",
      github_url: "https://github.com/harukishimo/design_lv1_canceled",
      note: "Canceled review scenario."
    )
    ReviewApplications::CancelService.call(
      review_application: canceled_review,
      actor: candidates.fetch(:rails),
      cancel_reason: "デモ用の取り消しデータ"
    ) if canceled_review.cancelable?

    primary_profile.update!(monthly_interview_count: 2)
    backup_profile.update!(monthly_interview_count: 1)
    infra_profile.update!(monthly_interview_count: 4)
    no_language_profile.update!(monthly_interview_count: 7)

    unless Rails.env.test?
      puts "Demo accounts:"
      puts "  admin@example.com / #{DEMO_PASSWORD}"
      puts "  candidate@example.com - candidate8@example.com / #{DEMO_PASSWORD}"
      puts "  examiner@example.com - examiner4@example.com / #{DEMO_PASSWORD}"
      puts "Demo master records: #{SkillArea.active.count} active skill areas, #{ProgrammingLanguage.active.count} active languages, #{EvaluationTarget.active.count} active evaluation targets"
      puts "Demo workflow records: #{ExamApplication.count} exams, #{ReviewApplication.count} reviews, #{InterviewApplication.count} interviews"
    end
  end
end
