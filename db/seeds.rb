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
  record = relation.find_or_initialize_by(lookup)
  record.restore(recursive: false) if record.respond_to?(:deleted?) && record.deleted?
  yield record
  record.save!
  record
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

  seed_record(
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
end
