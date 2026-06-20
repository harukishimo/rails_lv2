# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

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
    record.password = "password123"
    record.password_confirmation = "password123"
    record.active = true if record.respond_to?(:active=)
  end

  roles.each do |code|
    role = Role.find_by!(code: code)
    UserRole.find_or_create_by!(user: user, role: role)
  end

  user
end

def seed_examiner_profile(user:, display_name:, monthly_interview_count: 0)
  seed_record(ExaminerProfile, user: user) do |record|
    record.display_name = display_name
    record.active = true
    record.can_review = true
    record.can_interview = true
    record.monthly_interview_count = monthly_interview_count
    record.max_monthly_interviews = 10
  end
end

def seed_examiner_capability(profile:, target:)
  seed_record(ExaminerSkillCapability, examiner_profile: profile, evaluation_target: target) do |record|
    record.active = true
    record.can_review = true
    record.can_interview = true
  end
end

def seed_github_submission(review_application:, title:, github_url:)
  seed_record(Submission, review_application: review_application, title: title) do |record|
    record.kind = :github_repository
    record.github_url = github_url
    record.note = "Demo repository evidence for local walkthrough."
  end
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

if ActiveRecord::Base.connection.data_source_exists?("evaluation_periods")
  seed_record(EvaluationPeriod, name: "2026 Evaluation Period") do |record|
    record.starts_on = Date.new(2026, 1, 1)
    record.ends_on = Date.new(2026, 12, 31)
    record.active = true
  end
end

if %w[
  skill_areas
  programming_languages
  frameworks
  skill_levels
  evaluation_targets
].all? { |table_name| ActiveRecord::Base.connection.data_source_exists?(table_name) }
  backend = seed_record(SkillArea, name: "Backend") do |record|
    record.display_order = 10
    record.active = true
  end

  ruby = seed_record(ProgrammingLanguage, name: "Ruby") do |record|
    record.active = true
  end

  rails = seed_record(Framework, name: "Ruby on Rails", programming_language: ruby) do |record|
    record.active = true
  end

  rails_lv2 = seed_record(SkillLevel, code: "Lv2") do |record|
    record.numeric_level = 2
    record.active = true
  end

  go = seed_record(ProgrammingLanguage, name: "Go") do |record|
    record.active = true
  end

  go_lv3 = seed_record(SkillLevel, code: "Lv3") do |record|
    record.numeric_level = 3
    record.active = true
  end

  rails_target = seed_record(
    EvaluationTarget,
    programming_language: ruby,
    framework: rails,
    skill_level: rails_lv2,
    version: "2026.06"
  ) do |record|
    record.skill_area = backend
    record.external_knowledge_key = "ruby_on_rails_lv2"
    record.external_knowledge_url = "https://example.com/internal-knowledge/ruby-on-rails/lv2"
    record.description = "Ruby on Rails Lv2 evaluation target. Criteria body is managed outside this app."
    record.display_order = 10
    record.active = true
  end

  go_target = seed_record(
    EvaluationTarget,
    programming_language: go,
    framework: nil,
    skill_level: go_lv3,
    version: "2026.06"
  ) do |record|
    record.skill_area = backend
    record.external_knowledge_key = "go_lv3"
    record.external_knowledge_url = "https://example.com/internal-knowledge/go/lv3"
    record.description = "Go Lv3 evaluation target for cross-language demo data."
    record.display_order = 20
    record.active = true
  end

  if Rails.configuration.x.local_demo_enabled && %w[
    users
    user_roles
    examiner_profiles
    examiner_skill_capabilities
    exam_applications
    review_applications
    submissions
    interview_applications
    user_qualifications
  ].all? { |table_name| ActiveRecord::Base.connection.data_source_exists?(table_name) }
    admin = seed_user(email: "admin@example.com", name: "Demo Admin", roles: [ Role::ADMIN ])
    candidate = seed_user(email: "candidate@example.com", name: "Demo Candidate", roles: [ Role::CANDIDATE ])
    examiner = seed_user(email: "examiner@example.com", name: "Demo Examiner", roles: [ Role::EXAMINER ])
    backup_examiner = seed_user(email: "examiner2@example.com", name: "Backup Examiner", roles: [ Role::EXAMINER ])

    examiner_profile = seed_examiner_profile(user: examiner, display_name: "Demo Examiner", monthly_interview_count: 1)
    backup_profile = seed_examiner_profile(user: backup_examiner, display_name: "Backup Examiner", monthly_interview_count: 0)
    [ rails_target, go_target ].each do |target|
      seed_examiner_capability(profile: examiner_profile, target: target)
      seed_examiner_capability(profile: backup_profile, target: target)
    end

    period = EvaluationPeriod.find_by!(name: "2026 Evaluation Period")
    rails_exam = ExamApplication.find_by(
      evaluation_period: period,
      candidate: candidate,
      evaluation_target: rails_target,
      attempt_number: 1
    ) || ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: period,
      evaluation_target: rails_target,
      actor: candidate
    )

    review_application = rails_exam.review_applications.find_by(sequence_number: 1)
    unless review_application
      review_application = ReviewApplications::CreateService.call(
        exam_application: rails_exam,
        actor: candidate,
        attributes: {
          appeal_markdown: <<~MARKDOWN,
            ## Demo appeal

            - Rails workflow implementation
            - Review and interview evidence
            - Local demo seed data
          MARKDOWN
          submissions_attributes: {
            "0" => {
              kind: :github_repository,
              title: "SkillEvidenceHub demo repository",
              github_url: "https://github.com/harukishimo/rails_lv2",
              note: "Repository used for the evaluation demo."
            }
          }
        }
      )
    end
    seed_github_submission(
      review_application: review_application,
      title: "SkillEvidenceHub demo repository",
      github_url: "https://github.com/harukishimo/rails_lv2"
    )

    InterviewApplications::CreateService.call(exam_application: rails_exam, actor: candidate) unless rails_exam.interview_application

    go_exam = seed_record(
      ExamApplication,
      evaluation_period: period,
      candidate: candidate,
      evaluation_target: go_target,
      attempt_number: 1
    ) do |record|
      record.status = :closed
      record.declared_at ||= 30.days.ago
      record.result = :passed
      record.result_decided_at ||= 7.days.ago
      record.closed_at ||= 7.days.ago
    end

    seed_record(UserQualification, user: candidate, evaluation_target: go_target) do |record|
      record.exam_application = go_exam
      record.acquired_on = 7.days.ago.to_date
      record.granted_by = examiner
    end

    unless Rails.env.test?
      puts "Demo accounts: admin@example.com / candidate@example.com / examiner@example.com / password=password123"
      puts "Demo records: #{rails_target.display_name}, #{go_target.display_name}, review ##{review_application.id}"
    end
  end
end
