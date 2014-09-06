require 'paperclip-trusted-io/paperclip/io_adapters/abstract_adapter'
require 'paperclip-trusted-io/paperclip/io_adapters/trusted_io_adapter'
require 'paperclip-trusted-io/paperclip/trusted_io'
require 'paperclip-trusted-io/paperclip/attachment'
require 'paperclip-trusted-io/paperclip/has_attached_file'
require 'paperclip-trusted-io/paperclip/storage/filesystem'

module Paperclip
  require 'rails'

  class Railtie < Rails::Railtie

    initializer 'paperclip-trusted-io.add_trusted_io_adapter_to_paperclip' do
      Paperclip.io_adapters.register Paperclip::TrustedIOAdapter do |target|
        target.kind_of?(Paperclip::TrustedIO)
      end
    end
  end
end

