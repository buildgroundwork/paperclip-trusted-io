require 'paperclip/io_adapters/trusted_io_adapter'

describe Paperclip::TrustedIOAdapter do
  let(:adapter) { described_class.new(target) }
  let(:target) { Paperclip::TrustedIO.new(<<-TEXT, content_type: 'text/plain', filename: 'jabberwocky') }
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
end

