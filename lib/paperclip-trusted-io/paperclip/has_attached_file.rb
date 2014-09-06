class Paperclip::HasAttachedFile
  def add_required_validations
    name = @name
    @klass.validates_media_type_spoof_detection name,
      if: ->(instance) { instance.send(name).dirty? },
      unless: ->(instance) { instance.send(name).trusted? }
  end
end

