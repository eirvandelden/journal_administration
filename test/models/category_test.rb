require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "to_s returns name for parent categories" do
    cat = categories(:abonnementen)
    assert_equal "Abonnementen", cat.to_s
  end

  test "to_s returns 'Parent - Child' for child categories" do
    cat = categories(:abonnementen_streaming)
    assert_equal "Abonnementen - Streaming", cat.to_s
  end
end

