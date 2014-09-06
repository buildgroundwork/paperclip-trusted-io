require 'paperclip-trusted-io/paperclip/io_adapters/trusted_io_adapter'
require 'paperclip-trusted-io/paperclip/trusted_io'

describe Paperclip::TrustedIOAdapter do
  let(:adapter) { described_class.new(target) }
  let(:target) { Paperclip::TrustedIO.new(content, content_type: 'text/plain', filename: 'jabberwocky') }
  let(:content) { <<-TEXT }
    `Twas brillig, and the slithy toves
      Did gyre and gimble in the wabe:
    All mimsy were the borogoves,
      And the mome raths outgrabe.

    "Beware the Jabberwock, my son!
      The jaws that bite, the claws that catch!
    Beware the Jubjub bird, and shun
      The frumious Bandersnatch!"
  TEXT

  describe "#content_type" do
    subject { adapter.content_type }
    it { should == target.content_type }
  end

  describe "#original_filename" do
    subject { adapter.original_filename }
    it { should == target.original_filename }
  end

  describe "#size" do
    subject { adapter.size }
    it { should == target.size }
  end

  describe "#trusted?" do
    subject { adapter.trusted? }
    it { should be_truthy }
  end

  describe "#read" do
    subject { adapter.read }
    it { should == content }
  end

  describe "fingerprint" do
    subject { adapter.fingerprint }
    it { should == Digest::MD5.hexdigest(content) }

    it "should not change the read position" do
      expect { subject }.to_not change(target, :pos)
    end
  end

  describe "#binmode" do
    subject { adapter.binmode }
    it { should == target }
  end

  describe "#binmode?" do
    subject { adapter.binmode? }
    it { should be_falsy }
  end

  describe "#close!" do
    subject { -> { adapter.close! } }
    it { should change(target, :closed?).to be_truthy }
  end

  describe "unsupported methods" do
    subject { adapter }
    %i(path unlink).each do |method|
      it { should_not respond_to(method) }
    end
  end
end

