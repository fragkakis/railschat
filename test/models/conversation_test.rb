require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  # Validations

  test "is valid with required attributes" do
    conversation = Conversation.new(model_id: "gemini-2.5-flash", session_id: "s1")
    assert conversation.valid?
  end

  test "is invalid without model_id" do
    conversation = Conversation.new(session_id: "s1")
    assert_not conversation.valid?
    assert_includes conversation.errors[:model_id], "can't be blank"
  end

  test "auto-generates uuid before validation" do
    conversation = Conversation.new(model_id: "gemini-2.5-flash")
    assert_nil conversation.uuid
    conversation.valid?
    assert_not_nil conversation.uuid
  end

  test "uuid must be unique" do
    existing = conversations(:gemini_chat)
    duplicate = Conversation.new(model_id: "gpt-4o", uuid: existing.uuid)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:uuid], "has already been taken"
  end

  # provider_name

  test "provider_name returns Gemini for gemini model" do
    conversation = Conversation.new(model_id: "gemini-2.5-flash")
    assert_equal "Gemini", conversation.provider_name
  end

  test "provider_name returns OpenAI for gpt-4o" do
    conversation = Conversation.new(model_id: "gpt-4o")
    assert_equal "OpenAI", conversation.provider_name
  end

  test "provider_name returns OpenAI for gpt-4o-mini" do
    conversation = Conversation.new(model_id: "gpt-4o-mini")
    assert_equal "OpenAI", conversation.provider_name
  end

  test "provider_name returns Mistral for mistral-large-latest" do
    conversation = Conversation.new(model_id: "mistral-large-latest")
    assert_equal "Mistral", conversation.provider_name
  end

  test "provider_name returns nil for unknown model" do
    conversation = Conversation.new(model_id: "unknown-model")
    assert_nil conversation.provider_name
  end

  # requires_api_key?

  test "requires_api_key? is false for Gemini" do
    conversation = Conversation.new(model_id: "gemini-2.5-flash")
    assert_not conversation.requires_api_key?
  end

  test "requires_api_key? is true for OpenAI" do
    conversation = Conversation.new(model_id: "gpt-4o")
    assert conversation.requires_api_key?
  end

  test "requires_api_key? is true for Mistral" do
    conversation = Conversation.new(model_id: "mistral-large-latest")
    assert conversation.requires_api_key?
  end

  test "requires_api_key? is false for unknown model" do
    conversation = Conversation.new(model_id: "unknown-model")
    assert_not conversation.requires_api_key?
  end

  # Scopes

  test "for_session returns only conversations for the given session" do
    results = Conversation.for_session("session_abc123")
    assert_includes results, conversations(:gemini_chat)
    assert_includes results, conversations(:openai_chat)
    assert_not_includes results, conversations(:other_session_chat)
  end

  test "ordered returns conversations sorted by updated_at desc" do
    conversations(:gemini_chat).touch
    results = Conversation.for_session("session_abc123").ordered
    assert_equal conversations(:gemini_chat), results.first
  end

  # to_param

  test "to_param returns uuid" do
    conversation = conversations(:gemini_chat)
    assert_equal conversation.uuid, conversation.to_param
  end
end
