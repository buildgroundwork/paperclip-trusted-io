require 'paperclip'

class Paperclip::AbstractAdapter
  def trusted?
    false
  end
end

