require 'paperclip'

class Paperclip::Attachment
  def trusted?
    @file.trusted?
  end
end

