require "test_helper"

class UserTest < ActiveSupport::TestCase
  def valid_user_attrs
    {
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      terms_accepted: true
    }
  end

  test "valid user with all required fields" do
    user = User.new(valid_user_attrs)
    assert user.valid?, user.errors.full_messages.to_s
  end

  test "invalid without email" do
    user = User.new(valid_user_attrs.merge(email: ""))
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "invalid with duplicate email" do
    User.create!(valid_user_attrs)
    user2 = User.new(valid_user_attrs.merge(email: "test@example.com"))
    assert_not user2.valid?
    assert_includes user2.errors[:email], "has already been taken"
  end

  test "invalid without password" do
    user = User.new(valid_user_attrs.merge(password: "", password_confirmation: ""))
    assert_not user.valid?
  end

  test "invalid with password shorter than minimum length" do
    user = User.new(valid_user_attrs.merge(password: "short", password_confirmation: "short"))
    assert_not user.valid?
  end

  test "invalid when terms_accepted is false on create" do
    user = User.new(valid_user_attrs.merge(terms_accepted: false))
    assert_not user.valid?
  end

  test "blocked defaults to false" do
    user = User.create!(valid_user_attrs)
    assert_equal false, user.blocked
  end

  test "includes JTIMatcher revocation strategy" do
    assert User.ancestors.include?(Devise::JWT::RevocationStrategies::JTIMatcher)
  end

  test "responds to jwt_authenticatable modules" do
    assert User.devise_modules.include?(:jwt_authenticatable)
  end
end
