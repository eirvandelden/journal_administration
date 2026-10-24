require "test_helper"
require "open3"
require "json"

class LocaleNoLiteralTextTest < ActiveSupport::TestCase
  RULE = "locale-no-literal-text".freeze

  test "literal paragraph text is reported" do
    assert_reported "<p>Save</p>"
  end

  test "translated text is not reported" do
    assert_clean '<p><%= t(".save") %></p>'
  end

  test "literal placeholder is reported" do
    assert_reported '<input type="text" placeholder="Search">'
  end

  test "translated alt is not reported" do
    assert_clean '<img src="/a.png" alt="<%= t(".alt") %>">'
  end

  test "mixed title with a literal word is reported" do
    assert_reported '<a href="/" title="Open <%= t(".name") %>">x</a>'
  end

  test "entities and numbers are not reported" do
    assert_clean "<span>&nbsp;&times;&#160; 42 - %</span>"
  end

  test "script content is not reported" do
    assert_clean "<script>const word = \"hello\"</script><style>p { color: red }</style>"
  end

  test "pre text is reported" do
    assert_reported "<pre>Some words</pre>"
  end

  private

  def assert_reported(source)
    assert_includes offending_rules(source), RULE
  end

  def assert_clean(source)
    assert_not_includes offending_rules(source), RULE
  end

  def offending_rules(source)
    Dir.mktmpdir("herb", Rails.root.join("test")) do |dir|
      path = File.join(dir, "sample.html.erb")
      File.write(path, "#{source}\n")
      output, = Open3.capture2(herb_lint, "--no-timing", "--json", path, chdir: Rails.root.to_s)
      JSON.parse(output).fetch("offenses").pluck("code").uniq
    end
  end

  def herb_lint
    Rails.root.join("node_modules/.bin/herb-lint").to_s
  end
end
