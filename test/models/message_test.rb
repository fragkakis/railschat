require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "is valid with role user" do
    message = Message.new(conversation: conversations(:gemini_chat), role: "user", content: "Hi")
    assert message.valid?
  end

  test "is valid with role assistant" do
    message = Message.new(conversation: conversations(:gemini_chat), role: "assistant", content: "Hello!")
    assert message.valid?
  end

  test "is invalid with an unknown role" do
    message = Message.new(conversation: conversations(:gemini_chat), role: "system", content: "test")
    assert_not message.valid?
    assert_includes message.errors[:role], "is not included in the list"
  end

  test "is invalid without a conversation" do
    message = Message.new(role: "user", content: "orphan")
    assert_not message.valid?
  end

  test "content defaults to empty string" do
    message = messages(:gemini_user_msg)
    assert_not_nil message.content
  end
end
