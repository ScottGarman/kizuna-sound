require "test_helper"

class LinkTest < ActiveSupport::TestCase
  setup do
    @setting = Setting.create!
  end

  test "requires a title and a url" do
    link = Link.new(setting: @setting)
    assert_not link.valid?
    assert_includes link.errors[:title], "can't be blank"
    assert_includes link.errors[:url], "can't be blank"
  end

  test "accepts http and https urls" do
    assert Link.new(setting: @setting, title: "A", url: "http://example.com").valid?
    assert Link.new(setting: @setting, title: "B", url: "https://example.com/path").valid?
  end

  test "rejects non-http schemes and malformed urls" do
    %w[javascript:alert(1) data:text/html;base64,xxx ftp://example.com notaurl].each do |bad|
      link = Link.new(setting: @setting, title: "X", url: bad)
      assert_not link.valid?, "expected #{bad.inspect} to be rejected"
      assert_includes link.errors[:url], "must be a valid http:// or https:// URL"
    end
  end

  test "assigns incrementing positions in insertion order" do
    a = @setting.links.create!(title: "A", url: "https://a.example")
    b = @setting.links.create!(title: "B", url: "https://b.example")
    assert_operator a.position, :<, b.position
    assert_equal %w[A B], @setting.links.pluck(:title)
  end
end
