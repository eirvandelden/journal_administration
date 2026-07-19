class CreateAppkitPushSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :appkit_push_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :endpoint, null: false
      t.string :p256dh_key
      t.string :auth_key
      t.string :user_agent

      t.timestamps
    end
    add_index :appkit_push_subscriptions, :endpoint, unique: true
  end
end
