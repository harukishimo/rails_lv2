class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def update?
    false
  end

  def destroy?
    false
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.none
    end

    private

    attr_reader :user, :scope
  end

  private

  def active_user?
    user&.active_for_authentication?
  end

  def admin?
    active_user? && user.admin?
  end

  def candidate?
    active_user? && user.candidate?
  end

  def examiner?
    active_user? && user.examiner?
  end

  def examiner_capable_for?(evaluation_target)
    examiner? && user.examiner_profile&.can_evaluate?(evaluation_target)
  end
end
