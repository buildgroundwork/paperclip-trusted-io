require 'paperclip-trusted-io/paperclip/trusted_io'

describe Paperclip::TrustedIO do
  let(:trusted_io) { described_class.new(content, content_type: content_type, filename: filename) }
  let(:content) { <<-TEXT }
    It is a truth universally acknowledged, that a single man in possession of
    a good fortune, must be in want of a wife.

    However little known the feelings or views of such a man may be on his first
    entering a neighbourhood, this truth is so well fixed in the minds of the
    surrounding families, that he is considered the rightful property of some
    one or other of their daughters.
  TEXT
  let(:content_type) { 'text/plain' }
  let(:filename) { 'p-and-p' }

  # Paperclip provides the StringioAdapter, which will match any StringIO target.
  # The Paperclip adapter registry also provides no way to insert an adapter before
  # other adapters, so the StringioAdapter will almost certainly match before any
  # custom adapter.  If this class matches as a StringIO instance then that adapter
  # will match, and Paperclip will never try to use the TrustedIOAdapter for this
  # target.
  describe "#===" do
    subject { klass === trusted_io }

    context "for StringIO" do
      let(:klass) { StringIO }
      it { should_not be_truthy }
    end

    context "for TrustedIO" do
      let(:klass) { Paperclip::TrustedIO }
      it { should be_truthy }
    end
  end

  %i(is_a? kind_of? instance_of?).each do |method|
    describe method.to_s do
      subject { trusted_io.send(method, klass) }

      context "for StringIO" do
        let(:klass) { StringIO }
        it { should_not be_truthy }
      end

      context "for TrustedIO" do
        let(:klass) { Paperclip::TrustedIO }
        it { should be_truthy }
      end
    end
  end

  describe "#initialize" do
    subject { -> { trusted_io } }

    context "with not content type" do
      let(:content_type) { nil }
      it { should raise_error }
    end

    context "with no filename" do
      let(:filename) { nil }
      it { should raise_error }
    end
  end

  describe "#content_type" do
    subject { trusted_io.content_type }
    it { should == content_type }
  end

  describe "#original_filename" do
    subject { trusted_io.original_filename }
    it { should == filename }
  end

  describe "#size" do
    subject { trusted_io.size }
    it { should == content.size }
  end
end

