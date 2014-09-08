module Paperclip
  class TrustedIO < StringIO
    def initialize(content, content_type: , filename: )
      super(content)
      @content_type = content_type || raise("TrustedIO requires a content type")
      @original_filename = filename || raise("TrustedIO requires a filename")
    end

    attr_reader :content_type, :original_filename

    %i(kind_of? is_a?).each do |method|
      define_method(method) do |klass|
        klass == StringIO ? false : super(klass)
      end
    end
  end

  module TrustedIOAnonymization
    def self.extended(klass)
      klass.instance_eval do
        def ===(rhs)
          self != TrustedIO && rhs.kind_of?(TrustedIO) ? false : super
        end
      end
    end
  end
end

StringIO.instance_eval { extend Paperclip::TrustedIOAnonymization }

