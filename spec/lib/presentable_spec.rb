require "spec_helper"

RSpec.describe Presentable do
  class ExampleWithPresenter
    def initialize(obj) end
    def as_json(options={})
      4
    end
  end

  class ExampleWith
    include Presentable
  end

  class ExampleWithout
    def as_json(options={})
      3
    end
    include Presentable
  end

  it "should fall back to default as_json" do
    expect(ExampleWithout.new.as_json).to eq(3)
  end

  it "should use Presenter if it exists" do
    expect(ExampleWith.new.as_json).to eq(4)
  end
end
