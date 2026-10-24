require "test_helper"
require "rubocop/minitest/support"
require Rails.root.join("lib/rubocop/cop/locale/literal_message").to_s

class LiteralMessageTest < ActiveSupport::TestCase
  include RuboCop::Minitest::AssertOffense

  MSG = RuboCop::Cop::Locale::LiteralMessage::MSG

  test "reports notice variable assignment" do
    assert_offense(<<~RUBY)
      notice = "Saved"
               ^^^^^^^ #{MSG}
    RUBY
  end

  test "reports notice option" do
    assert_offense(<<~RUBY)
      redirect_to root_path, notice: "Saved"
                                     ^^^^^^^ #{MSG}
    RUBY
  end

  test "reports flash index assignment" do
    assert_offense(<<~RUBY)
      flash[:alert] = "Nope"
                      ^^^^^^ #{MSG}
    RUBY
  end

  test "reports flash now interpolated string" do
    assert_offense(<<~RUBY)
      flash.now[:alert] = "Failed: \#{reason}"
                          ^^^^^^^^^^^^^^^^^^^ #{MSG}
    RUBY
  end

  test "reports flash notice writer" do
    assert_offense(<<~RUBY)
      flash.notice = "Saved"
                     ^^^^^^^ #{MSG}
    RUBY
  end

  test "reports errors add string" do
    assert_offense(<<~RUBY)
      errors.add(:type, "must be a transfer")
                        ^^^^^^^^^^^^^^^^^^^^ #{MSG}
    RUBY
  end

  test "reports validation message string" do
    assert_offense(<<~RUBY)
      validates :name, presence: { message: "is required" }
                                            ^^^^^^^^^^^^^ #{MSG}
    RUBY
  end

  test "accepts translated notice" do
    assert_no_offenses(<<~RUBY)
      redirect_to root_path, notice: t(".saved")
      flash[:alert] = t("errors.nope")
    RUBY
  end

  test "accepts errors add symbol" do
    assert_no_offenses(<<~RUBY)
      errors.add(:type, :invalid_type)
    RUBY
  end

  test "accepts raise string" do
    assert_no_offenses(<<~RUBY)
      raise ArgumentError, "cents must be an integer"
    RUBY
  end

  test "accepts emoji only notice" do
    assert_no_offenses(<<~RUBY)
      notice = "✅"
    RUBY
  end

  private

  def cop_class
    RuboCop::Cop::Locale::LiteralMessage
  end
end
