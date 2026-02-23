class AddUuidToConversations < ActiveRecord::Migration[8.0]
  def change
    add_column :conversations, :uuid, :string

    reversible do |dir|
      dir.up do
        Conversation.reset_column_information
        Conversation.find_each do |c|
          c.update_column(:uuid, SecureRandom.uuid)
        end

        change_column_null :conversations, :uuid, false
      end
    end

    add_index :conversations, :uuid, unique: true
  end
end
