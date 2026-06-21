module Admin
  class UsersController < ApplicationController
    before_action :authenticate_user!
    before_action :set_user, only: %i[show edit update]
    before_action :set_roles, only: %i[index new create edit update]

    def index
      authorize([ :admin, User ], :index?)
      @users = policy_scope([ :admin, User ]).includes(:roles, :examiner_profile).order(:id)
      @users = filter_users(@users)
    end

    def show
      authorize([ :admin, @user ])
    end

    def new
      @user = User.new(active: true)
      authorize([ :admin, @user ])
    end

    def create
      @user = User.new(user_params)
      authorize([ :admin, @user ])
      role_codes = selected_role_codes

      User.transaction do
        @user.save!
        sync_roles(@user, role_codes)
        ensure_examiner_profile(@user) if role_codes.include?(Role::EXAMINER)
      end

      redirect_to admin_user_path(@user), notice: "ユーザーを作成しました"
    rescue ActiveRecord::RecordInvalid
      render :new, status: :unprocessable_entity
    end

    def edit
      authorize([ :admin, @user ])
    end

    def update
      authorize([ :admin, @user ])
      role_codes = selected_role_codes

      User.transaction do
        @user.update!(user_params_for_update)
        deactivate_examiner_profile(@user) unless role_codes.include?(Role::EXAMINER)
        sync_roles(@user, role_codes)
        ensure_examiner_profile(@user) if role_codes.include?(Role::EXAMINER)
      end

      redirect_to admin_user_path(@user), notice: "ユーザーを更新しました"
    rescue ActiveRecord::RecordInvalid
      render :edit, status: :unprocessable_entity
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def set_roles
      @roles = Role.active.order(:code)
    end

    def filter_users(scope)
      scope = filter_users_by_keyword(scope)
      scope = scope.joins(:roles).where(roles: { code: params[:role] }) if params[:role].present?
      scope = scope.where(active: ActiveModel::Type::Boolean.new.cast(params[:active])) if params[:active].present?
      scope.distinct
    end

    def filter_users_by_keyword(scope)
      return scope if params[:keyword].blank?

      keyword = "%#{ActiveRecord::Base.sanitize_sql_like(params[:keyword].strip)}%"
      scope.where("users.name LIKE :keyword OR users.email LIKE :keyword", keyword: keyword)
    end

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :active)
    end

    def user_params_for_update
      permitted = user_params
      if permitted[:password].blank? && permitted[:password_confirmation].blank?
        permitted = permitted.except(:password, :password_confirmation)
      end
      permitted
    end

    def selected_role_codes
      Array(params.dig(:user, :role_codes)).compact_blank & Role::CODES
    end

    def sync_roles(user, role_codes)
      roles = Role.active.where(code: role_codes).to_a
      user.roles = roles
    end

    def ensure_examiner_profile(user)
      return if user.examiner_profile.present?

      user.create_examiner_profile!(display_name: user.name, active: true)
    end

    def deactivate_examiner_profile(user)
      return if user.examiner_profile.blank?

      user.examiner_profile.update!(active: false, can_review: false, can_interview: false)
    end
  end
end
