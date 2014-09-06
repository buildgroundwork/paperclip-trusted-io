module Paperclip
  class TrustedIO
    def initialize(content, content_type: , filename: )
      @content_type = content_type || raise("TrustedIO requires a content type")
      @original_filename = filename || raise("TrustedIO requires a filename")
      @size = content.size
    end

    attr_reader :content_type, :original_filename, :size
  end
end

