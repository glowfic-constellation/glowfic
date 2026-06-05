class StubJob < ApplicationJob
  queue_as :high
  def perform(*_args)
    raise NotImplementedError
  end
end

RSpec.describe ApplicationJob do
  include ActiveJob::TestHelper

  before(:each) { clear_enqueued_jobs }

  it "retries on sigterm" do
    exception = Resque::TermException.new(15)
    job = StubJob.new(1)
    allow(StubJob).to receive(:new).and_return(job)
    allow(job).to receive(:perform).and_raise(exception)
    expect(job).to receive(:perform)
    job.perform_now
    expect(StubJob).to have_been_enqueued.with(1).on_queue('high')
  end

  skip "retries on error" do
    job = StubJob.new(1)
    allow(StubJob).to receive(:new).and_return(job)
    allow(job).to receive(:perform).and_raise(StandardError)
    expect(job).to receive(:perform)
    job.perform_now
    expect(StubJob).to have_been_enqueued.with(1).on_queue('high')
  end

  it "sends email when retry gives up" do
    exc = StandardError.new
    expect(StubJob).to receive(:notify_exception).with(exc, 2, :test).and_call_original
    expect(ExceptionNotifier).to receive(:notify_exception).with(exc, data: { job: StubJob.name, args: [2, :test] })

    job = StubJob.new(2, :test)
    allow(job).to receive(:perform).and_raise(exc)
    expect(job).to receive(:perform)
    begin
      job.perform_now
    rescue Exception # rubocop:disable Lint/RescueException
    else
      raise "Error should be handled"
    end
  end

  it "yells if you try to call process" do
    expect { StubJob.perform_now(1) }.to raise_error(NotImplementedError)
  end
end
