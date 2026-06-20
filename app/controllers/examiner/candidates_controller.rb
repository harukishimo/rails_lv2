module Examiner
  class CandidatesController < ApplicationController
    before_action :authenticate_user!

    def index
      authorize User, :candidate_index?

      candidates = Search::ExaminerCandidateSearch.new(
        policy_scope(User),
        search_params,
        visible_evaluation_target_ids: search_visible_evaluation_target_ids
      ).relation

      render plain: candidates.map { |candidate| candidate_line(candidate) }.join("\n")
    end

    def show
      candidate = Search::ExaminerCandidateSearch.new(
        policy_scope(User),
        {},
        visible_evaluation_target_ids: search_visible_evaluation_target_ids
      ).relation.find(params[:id])
      authorize candidate, :candidate_show?

      render plain: candidate_detail(candidate)
    end

    private

    def search_params
      params.permit(
        :keyword,
        :status,
        :evaluation_target_id,
        :page,
        :per_page
      )
    end

    def candidate_line(candidate)
      [
        "candidate=#{candidate.id}",
        "#{candidate.name}<#{candidate.email}>",
        "exam_applications=#{visible_exam_applications(candidate).size}",
        "qualifications=#{visible_qualifications(candidate).size}"
      ].join(" | ")
    end

    def candidate_detail(candidate)
      [
        candidate_line(candidate),
        qualification_lines(candidate),
        exam_application_lines(candidate)
      ].flatten.join("\n")
    end

    def qualification_lines(candidate)
      visible_qualifications(candidate).sort_by { |qualification| [ qualification.acquired_on, qualification.id ] }.reverse.map do |qualification|
        [
          "qualification=#{qualification.id}",
          qualification.evaluation_target.display_name,
          "acquired_on=#{qualification.acquired_on}",
          "granted_by=#{qualification.granted_by.name}"
        ].join(" | ")
      end
    end

    def exam_application_lines(candidate)
      visible_exam_applications(candidate).sort_by { |exam_application| [ exam_application.created_at, exam_application.id ] }.reverse.map do |exam_application|
        [
          "exam_application=#{exam_application.id}",
          "status=#{exam_application.status}",
          "target=#{exam_application.evaluation_target.display_name}"
        ].join(" | ")
      end
    end

    def visible_exam_applications(candidate)
      filter_by_visible_target(candidate.exam_applications)
    end

    def visible_qualifications(candidate)
      filter_by_visible_target(candidate.user_qualifications.select { |qualification| qualification.revoked_at.nil? })
    end

    def filter_by_visible_target(records)
      return records if current_user.admin?

      target_ids = visible_evaluation_target_ids
      records.select { |record| target_ids.include?(record.evaluation_target_id) }
    end

    def visible_evaluation_target_ids
      @visible_evaluation_target_ids ||= begin
        visible_capability_scope(current_user.examiner_profile).pluck(:evaluation_target_id)
      end
    end

    def search_visible_evaluation_target_ids
      return nil if current_user.admin?

      visible_evaluation_target_ids
    end

    def visible_capability_scope(profile)
      return ExaminerSkillCapability.none unless profile&.active?

      capabilities = profile.examiner_skill_capabilities.active
      visible = ExaminerSkillCapability.none
      visible = visible.or(capabilities.where(can_review: true)) if profile.can_review?
      visible = visible.or(capabilities.where(can_interview: true)) if profile.can_interview?
      visible
    end
  end
end
