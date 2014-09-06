require 'paperclip-trusted-io/paperclip/io_adapters/abstract_adapter'

describe Paperclip::AbstractAdapter do
  let(:adapter) { described_class.new }

  describe "#trusted?" do
    subject { adapter.trusted? }
    it { should_not be_truthy }
  end
end

