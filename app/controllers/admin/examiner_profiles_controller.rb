module Admin
  class ExaminerProfilesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_evaluation_targets, only: %i[index edit update]
    before_action :set_examiner_profile, only: %i[edit update]

    def index
      authorize([ :admin, ExaminerProfile ], :index?)
      @examiner_profiles = policy_scope([ :admin, ExaminerProfile ])
                             .includes(:user, examiner_skill_capabilities: :evaluation_target)
                             .order(:id)
      @examiner_profiles = filter_profiles(@examiner_profiles)
    end

    def edit
      authorize([ :admin, @examiner_profile ])
    end

    def update
      authorize([ :admin, @examiner_profile ])

      ExaminerProfile.transaction do
        @examiner_profile.update!(examiner_profile_params)
        sync_capabilities(@examiner_profile) if @examiner_profile.active?
      end

      redirect_to admin_examiner_profiles_path, notice: "評価官プロフィールを更新しました"
    rescue ActiveRecord::RecordInvalid
      render :edit, status: :unprocessable_entity
    end

    private

    def set_evaluation_targets
      @evaluation_targets = EvaluationTarget.active.includes(:programming_language, :framework, :skill_level).ordered
    end

    def set_examiner_profile
      @examiner_profile = ExaminerProfile.includes(:user, examiner_skill_capabilities: :evaluation_target).find(params[:id])
    end

    def filter_profiles(scope)
      scope = filter_profiles_by_keyword(scope)
      scope = filter_profiles_by_active(scope)
      scope = filter_profiles_by_evaluation_target(scope)
      scope.distinct
    end

    def filter_profiles_by_keyword(scope)
      return scope if params[:keyword].blank?

      keyword = "%#{ActiveRecord::Base.sanitize_sql_like(params[:keyword].strip)}%"
      scope.joins(:user).where(
        "examiner_profiles.display_name LIKE :keyword OR users.name LIKE :keyword OR users.email LIKE :keyword",
        keyword: keyword
      )
    end

    def filter_profiles_by_active(scope)
      return scope if params[:active].blank?

      scope.where(active: ActiveModel::Type::Boolean.new.cast(params[:active]))
    end

    def filter_profiles_by_evaluation_target(scope)
      return scope if params[:evaluation_target_id].blank?

      scope.joins(:examiner_skill_capabilities).where(
        examiner_skill_capabilities: {
          evaluation_target_id: params[:evaluation_target_id],
          active: true
        }
      )
    end

    def examiner_profile_params
      params.require(:examiner_profile).permit(
        :display_name,
        :active,
        :can_review,
        :can_interview,
        :monthly_interview_count,
        :max_monthly_interviews
      )
    end

    def selected_review_target_ids
      Array(params.dig(:examiner_profile, :review_evaluation_target_ids)).compact_blank.map(&:to_i)
    end

    def selected_interview_target_ids
      Array(params.dig(:examiner_profile, :interview_evaluation_target_ids)).compact_blank.map(&:to_i)
    end

    def sync_capabilities(profile)
      requested_ids = (selected_review_target_ids | selected_interview_target_ids)
      active_target_ids = EvaluationTarget.active.where(id: requested_ids).pluck(:id)

      profile.examiner_skill_capabilities.each do |capability|
        if active_target_ids.include?(capability.evaluation_target_id)
          capability.update!(
            active: true,
            can_review: selected_review_target_ids.include?(capability.evaluation_target_id),
            can_interview: selected_interview_target_ids.include?(capability.evaluation_target_id)
          )
        else
          deactivate_capability!(capability)
        end
      end

      missing_ids = active_target_ids - profile.examiner_skill_capabilities.map(&:evaluation_target_id)
      missing_ids.each do |target_id|
        profile.examiner_skill_capabilities.create!(
          evaluation_target_id: target_id,
          active: true,
          can_review: selected_review_target_ids.include?(target_id),
          can_interview: selected_interview_target_ids.include?(target_id)
        )
      end
    end

    def deactivate_capability!(capability)
      capability.active = false
      capability.can_review = false
      capability.can_interview = false
      capability.save!(validate: capability.evaluation_target&.active?)
    end
  end
end
