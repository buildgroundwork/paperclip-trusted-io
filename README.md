# Paperclip::TrustedIO

`Paperclip::TrustedIO` is a simple IO class that behaves as a StringIO with a bit of Paperclip-specific metadata.

`Paperclip::TrustedIOAdapter` is an implementation of Paperclip::AbstractAdapter which informs Paperclip's handling of TrustedIO objects.  It avoids the use of the file system, and tells Paperclip to simply use the content type provided.

As of version 4.0 Paperclip now copies all data to the file system before creating an attachment.  It does this, it seems, primarily for the purpose of programmatically determining the file content type in order to prevent spoofing.  This is well and good in the case when a user uploads a file, but many times a system generates files itself and uses Paperclip to store that content.  In this case, Paperclip should trust the content type provided by the system.  This avoids two significant problems:

1. File system transience.  Hosting providers don't necessarily make any guarantees about how, or if, a web application may use the file system.  It is possible that what an application sees as the file system may disappear at inopportune times.  Web applications should avoid depending on the file system if at all possible.

2. The difficulty of programmatically determining file content type.  Paperclip doesn't always (or frequently) get this right.  For instance, if you generate and attach CSV content, Paperclip will set the content type to 'text/plain.'

Along with programmatically determining content type, Paperclip has made content type validations more restrictive.  You can get around the problem of Paperclip incorrectly setting the content type by explicitly turning off content type validation, but if you're always generating CSV it seems reasonable you should be able to validate that attachments are always CSV.  In addition, turning off validation doesn't get around the unnecessary use of the file system.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'paperclip-trusted-io'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install paperclip-trusted-io

## Usage

`PaperClip::TrustedIO` requires that you explicitly specify a content type and filename.  It will pass these values directly on to Paperclip.

``` ruby
class Foo < ActiveRecord::Base
  has_attached_file :wibble

  def attach_some_content(content)
    self.wibble = Paperclip::TrustedIO.new(content, content_type: 'application/wibble', filename: 'wibble1')
  end
end

```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/paperclip-trusted-io/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

