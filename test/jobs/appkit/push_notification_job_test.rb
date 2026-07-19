require "test_helper"

module Appkit
  class PushNotificationJobTest < ActiveJob::TestCase
    setup do
      @subscription = users(:member).push_subscriptions.create!(
        endpoint: "https://push.example.com/abc",
        p256dh_key: "p256dh",
        auth_key: "auth"
      )
    end

    test "solid_queue is configured as JA's ActiveJob backend in production" do
      production_config = File.read(Rails.root.join("config/environments/production.rb"))

      assert_match(/config\.active_job\.queue_adapter\s*=\s*:solid_queue/, production_config)
    end

    test "round-trips through the queue and delivers via the web-push gateway" do
      gateway = Class.new do
        cattr_accessor :calls
        self.calls = []

        def self.payload_send(**args)
          calls << args
        end
      end
      Appkit::PushNotificationJob.gateway = gateway

      perform_enqueued_jobs do
        Appkit::PushNotificationJob.perform_later(@subscription, { title: "Hello" })
      end

      assert_equal 1, gateway.calls.size
      assert_equal @subscription.endpoint, gateway.calls.first[:endpoint]
    ensure
      Appkit::PushNotificationJob.gateway = WebPush
    end
  end
end
