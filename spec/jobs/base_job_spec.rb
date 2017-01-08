require "spec_helper"

RSpec.describe BaseJob do
  it "retries on sigterm" do
    ResqueSpec.reset!
    exception = Resque::TermException.new(15)
    expect(BaseJob).to receive(:process).and_raise(exception)
    BaseJob.instance_variable_set(:@queue, :high) # since BaseJob doesn't normally have a queue
    BaseJob.perform(1)
    expect(BaseJob).to have_queued(1).in(:high)
  end

  it "sends email when retry gives up" do
    exc = Exception.new
    expect(ExceptionNotifier).to receive(:notify_exception).with(exc, data: {job: BaseJob.name, args: [2, :test]})
    BaseJob.notify_exception(exc, 2, :test)
  end

  it "yells if you try to call process" do
    expect { BaseJob.perform(1) }.to raise_error(NotImplementedError)
  end
end
