require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "normalizes name to lower-case, trimmed, single-spaced" do
    tag = Tag.create!(name: "  Field   Recording  ")
    assert_equal "field recording", tag.name
  end

  test "requires a name" do
    tag = Tag.new(name: "   ")
    assert_not tag.valid?
    assert_includes tag.errors[:name], "can't be blank"
  end

  test "enforces unique names regardless of original casing/spacing" do
    Tag.create!(name: "Ambient")
    dup = Tag.new(name: "  ambient ")
    assert_not dup.valid?
    assert_includes dup.errors[:name], "has already been taken"
  end

  test "normalize matches find_or_create round-trips" do
    tag = Tag.find_or_create_by(name: Tag.normalize("RAIN"))
    assert_equal tag, Tag.find_or_create_by(name: Tag.normalize("  rain "))
    assert_equal 1, Tag.where(name: "rain").count
  end
end
