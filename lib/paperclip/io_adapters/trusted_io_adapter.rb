require 'paperclip'

module Paperclip
  class TrustedIOAdapter < AbstractAdapter
    def initialize(target)
      @target = target
      cache_attributes
    end

    attr_writer :content_type, :size

    private

    def cache_attributes
      @content_type = @target.content_type
      @original_filename = @target.original_filename
      @size = @target.size
    end
  end
end

