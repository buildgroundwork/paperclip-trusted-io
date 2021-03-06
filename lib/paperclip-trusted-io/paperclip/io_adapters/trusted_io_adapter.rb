require 'paperclip'

module Paperclip
  class TrustedIOAdapter < AbstractAdapter
    delegate :read, :binmode, :close, :closed?, :eof?, :rewind, :to => :target
    undef_method :path, :unlink

    def initialize(target)
      @target = target
      cache_attributes
    end

    attr_writer :content_type, :size
    alias_method :close!, :close

    def trusted?
      true
    end

    def fingerprint
      pos = target.pos
      target.rewind
      @fingerprint ||= Digest::MD5.hexdigest(target.read)
      target.seek(pos)
      @fingerprint
    end

    def binmode?
      false
    end

    private

    attr_reader :target

    def cache_attributes
      @content_type = target.content_type
      @original_filename = target.original_filename
      @size = target.size
    end
  end
end

