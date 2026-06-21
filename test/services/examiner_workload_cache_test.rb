require "test_helper"

class ExaminerWorkloadCacheTest < ActiveSupport::TestCase
  test "fetch protects shared workload cache with mutex under concurrent access" do
    profile = create_examiner_profile(monthly_interview_count: 4, max_monthly_interviews: 8)
    cache = ExaminerWorkloadCache.new

    workloads = 10.times.map do
      Thread.new do
        20.times.map { cache.fetch(profile) }
      end
    end.flat_map(&:value)

    assert_equal 1, cache.size
    assert_equal 1, workloads.map(&:object_id).uniq.size
    assert workloads.first.frozen?
    assert_equal [ 4, profile.id ], workloads.first.sort_key
    assert_equal 8, workloads.first.max_monthly_interviews
  end

  test "clear removes cached workload snapshots" do
    profile = create_examiner_profile(monthly_interview_count: 1)
    cache = ExaminerWorkloadCache.new

    cache.fetch(profile)
    assert_equal 1, cache.size

    cache.clear
    assert_equal 0, cache.size
  end

  private

  def create_examiner_profile(monthly_interview_count:, max_monthly_interviews: nil)
    role = Role.find_or_create_by!(code: Role::EXAMINER) do |record|
      record.name = Role::NAMES.fetch(Role::EXAMINER)
    end
    user = User.create!(
      name: "Examiner #{SecureRandom.hex(4)}",
      email: "examiner-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    UserRole.create!(user: user, role: role)
    ExaminerProfile.create!(
      user: user,
      display_name: "Examiner #{SecureRandom.hex(4)}",
      monthly_interview_count: monthly_interview_count,
      max_monthly_interviews: max_monthly_interviews
    )
  end
end
