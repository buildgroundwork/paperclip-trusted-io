# Paperclip::TrustedIO

`Paperclip::TrustedIO` is a simple IO class that behaves as a StringIO with a bit of Paperclip-specific metadata.

`Paperclip::TrustedIOAdapter` is an implementation of Paperclip::AbstractAdapter which informs Paperclip's handling of TrustedIO objects.  It avoids the use of the file system, and tells Paperclip to simply use the content type provided.

In addition, bits and pieces of modifications to Paperclip itself, to eliminate unnecessary assumptions about the source of content.

## Justification

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

## The Sordid Details

Assume you want to attach some content to a record using Paperclip.  You can assign an IO object, with a bit of additional metadata, into the attachment property:

``` ruby
class TypedIO < StringIO
  def initialize(content, content_type: , original_filename: )
    ...
  end
end

foo = Foo.new
foo.wibble = TypedIO.new(content, content_type: 'application/xml', original_filename: 'my_content')
```

Prior to version 4.0, Paperclip would accept the provided `content_type` metadata and stream the content of the IO object to its eventual home (file system, S3, etc.).  As of version 4.0, Paperclip has become much less trusting, so it wraps the provided IO object into an adapter object, with different types of adapters for different IO objects.  Once wrapped, Paperclip tries to verify the `content_type` of the provided content in various ways.  For instance, if you provide a StringIO object, Paperclip will save it to a temporary file and use the file system to interrogate the resulting file for its type:

``` ruby
# from lib/paperclip/file_command_content_type_detector.rb

def type_from_file_command
  type = begin
    # On BSDs, `file` doesn't give a result code of 1 if the file doesn't exist.
    Paperclip.run("file", "-b --mime :file", :file => @filename)
  rescue Cocaine::CommandLineError => e
    Paperclip.log("Error while determining content type: #{e}")
    SENSIBLE_DEFAULT
  end

  if type.nil? || type.match(/\(.*?\)/)
    type = SENSIBLE_DEFAULT
  end
  type.split(/[:;\s]+/)[0]
end
```

This library avoids this check (and the file copy) by registering the `Paperclip::TrustedIOAdapter` adapter.  Paperclip will wrap any instance of `Paperclip::TrustedIO` assigned into an attachment property with this adapter, which skips the content check; it simply trusts the `content_type` value you give it.

Now we have:

``` ruby
foo = Foo.new
foo.wibble = Paperclip::TrustedIO.new(content, content_type: 'application/xml', original_filename: 'my_content')
```

Unfortunately, Paperclip isn't done trying to copy this content to the file system.  When you save your record, and the associated attachment, Paperclip will run some fairly restrictive validations.  One of these validations, *which you cannot turn off*, is the dreaded `validates_media_type_spoof_detection`.  You have likely seen posts about avoiding this validation around the Internet that contain this (terrible) code:

``` ruby
require 'paperclip/media_type_spoof_detector'
module Paperclip
  class MediaTypeSpoofDetector
    def spoofed?
      false
    end
  end
end
```

We actually do want Paperclip to prevent type spoofing, but we want to tell Paperclip to not bother when it really should trust us.  Also, this validation uses the `MediaTypeSpoofDetectionValidator` class:

``` ruby
module Paperclip
  module Validators
    class MediaTypeSpoofDetectionValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        adapter = Paperclip.io_adapters.for(value)  # <==== N.B.
        if Paperclip::MediaTypeSpoofDetector.using(adapter, value.original_filename).spoofed?
          record.errors.add(attribute, :spoofed_media_type)
        end
      end
    end

    ...
```

Note that the validator is wrapping the attachment in an adapter, just as it did when we assigned the original content.  However, in this case it's wrapping the value passed to the validator, which isn't the content itself but the `Paperclip::Attachment` object that contains the content.  So, now we have an adapter that wraps an attachment that contains an adapter that wraps the original content.  Unfortunately, all Paperclip adapters make one fundamental assumption: they copy content to a temporary file on the file system; this behavior is in the `Paperclip::AbstractAdapter` base class.  Worse, the outer adapter doesn't ask the inner adapter for the content to store in a temporary file, but it asks the inner adapter for its temporary file and then copies from one temporary file to another.

Just to make this clear:

- We assign content to an attachment property.
- Paperclip wraps content in an content-specific adapter (A1); A1 write the content to a temporary file (F1).
- Other stuff happens and indeterminate time passes.
- We save the record.
- Paperclip validations run.
- Paperclip wraps A1 in another adapter (A2); A2 copied content from F1 to a new temporary file (F2).

Assuming a transient file system (and unless you're hosting on your own physical machines you have to assume a transient file system) F1 may be long gone by the time F2 tries to copy it.  We still have the original content held by A1; A2 should ask A1 for content, not a file path.

Getting around this was a bit trickier, and required modifying Paperclip slightly.  Each Paperclip adapter now responds to the `#trusted?` method; by default all standard adapters return false, but the `Paperclip::TrustedIOAdapter` returns true.  The `Paperclip::Attachment` object also responds to `#trusted?` by simply forwarding the message to the adapter it has cached for writing.  Finally, Paperclip will skip the media spoofing detection for trusted attachments:

``` ruby
class Paperclip::HasAttachedFile
  def add_required_validations
    name = @name
    @klass.validates_media_type_spoof_detection name,
      if: ->(instance) { instance.send(name).dirty? },
      unless: ->(instance) { instance.send(name).trusted? } # <==== Added this line
  end
end
```

**But wait**, there's more.

After validations have passed Paperclip has to write the content to its final destination.  If Paperclip writes to S3 this works fine, since the AWS-SDK gem expects to receive an IO object; it reads content from the IO object and all is well.  However, when saving to the file system, Paperclip assumes that the content will come from a file (F2), and therefore tries to simply move that file from its temporary location to its permanent location (F2').  Since our goal has been to avoid the file system, the Paperclip::TrustedIOAdapter never writes content to a file and the file move fails.

Unfortunately, fixing this required replacing the entire `#flush_writes` method for `Paperclip::Storage::Filesystem`.  However, that method already tries to fall back to reading from a stream if the system call made to move the file fails (i.e. throws a `SystemCallError` exception), so the change simply removes the file move attempt and defaults to the correct behavior:

``` ruby
@queued_for_write.each do |style_name, file|
  FileUtils.mkdir_p(File.dirname(path(style_name)))
  # begin
    # FileUtils.mv(file.path, path(style_name))
  # rescue SystemCallError
    File.open(path(style_name), "wb") do |new_file|
      while chunk = file.read(16 * 1024)
        new_file.write(chunk)
      end
    end
  # end
  ...
```

The original code remains in the modified method, simply to make clear what was changed.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/paperclip-trusted-io/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

