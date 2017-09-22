require "spec_helper"

class StubJob < ApplicationJob
  queue_as :high
  def perform(*args)
    raise NotImplementedError
  end
end

RSpec.describe ApplicationJob do
  include ActiveJob::TestHelper
  before(:each) { clear_enqueued_jobs }
  it "retries on sigterm" do
    exception = Resque::TermException.new(15)
    expect_any_instance_of(StubJob).to receive(:perform).and_raise(exception)
    StubJob.perform_now(1)
    expect(StubJob).to have_been_enqueued.with(1).on_queue('high')
  end

  it "retries on error" do
    expect_any_instance_of(StubJob).to receive(:perform).and_raise(StandardError)
    StubJob.perform_now(1)
    expect(StubJob).to have_been_enqueued.with(1).on_queue('high')
  end

  it "sends email when retry gives up" do
    exc = Exception.new
    expect(ExceptionNotifier).to receive(:notify_exception).with(exc, data: {job: StubJob.name, args: [2, :test]})
    StubJob.notify_exception(exc, 2, :test)
  end

  it "yells if you try to call process" do
    expect { StubJob.perform_now(1) }.to raise_error(NotImplementedError)
  end
end
