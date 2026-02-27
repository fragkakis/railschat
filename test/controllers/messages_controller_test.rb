require "test_helper"
require "ostruct"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  SESSION_ID = "session_abc123"

  setup do
    ApplicationController.any_instance.stubs(:current_session_id).returns(SESSION_ID)
    ApplicationController.any_instance.stubs(:ensure_session_id)
    @conversation = conversations(:gemini_chat)
  end

  test "client disconnect saves partial assistant message" do
    fake_chat = mock("chat")
    fake_chat.stubs(:add_message)

    # Yield one chunk then raise ClientDisconnected (bubbles out through ask's block)
    fake_chat.stubs(:ask).with("Hello")
      .yields(OpenStruct.new(content: "Hello "))
      .raises(ActionController::Live::ClientDisconnected)

    RubyLLM.stubs(:chat).returns(fake_chat)

    assert_difference -> { @conversation.messages.count }, 2 do # user + partial assistant
      post conversation_messages_path(@conversation),
        params: { content: "Hello" },
        headers: { "Content-Type" => "application/x-www-form-urlencoded" }
    end

    assistant_msg = @conversation.messages.where(role: "assistant").last
    assert assistant_msg.present?, "Expected a partial assistant message to be saved"
    assert_includes assistant_msg.content, "Hello "
  end

  test "client disconnect with no chunks does not save empty message" do
    fake_chat = mock("chat")
    fake_chat.stubs(:add_message)

    # Raise before yielding any chunks — assistant_content stays empty, nothing saved
    fake_chat.stubs(:ask).with("Hello")
      .raises(ActionController::Live::ClientDisconnected)

    RubyLLM.stubs(:chat).returns(fake_chat)

    # Only user message should be created (no empty assistant message)
    assert_no_difference -> { @conversation.messages.where(role: "assistant").count } do
      assert_difference -> { @conversation.messages.count }, 1 do
        post conversation_messages_path(@conversation),
          params: { content: "Hello" },
          headers: { "Content-Type" => "application/x-www-form-urlencoded" }
      end
    end
  end
end
