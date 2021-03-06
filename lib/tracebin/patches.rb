require 'tracebin/helpers'

module Tracebin
  ##
  # This singleton class handles patching for any given library we wish to
  # instrument. To create a new patch for a library, just create a file in the
  # +lib/patches+ directory with any name. These files typically contain code
  # that will monkeypatch a given library. When you wish to execute the code
  # in that file, just call its corresponding +patch_+ method. For example, if
  # we have a file +lib/patches/foo.rb+, then we would just call:
  #
  #   ::Tracebin::Patches.patch_foo
  #
  class Patches
    include ::Tracebin::Helpers

    PATCH_METHOD_REGEX = /^patch_(.*)$/

    class << self
      def handle_event(handler_name, event_data)
        handler = instance_variable_get "@#{handler_name}_event_handler"
        handler.call event_data unless handler.nil?
      end

      def method_missing(method_sym, *args, &block)
        if method_sym.to_s =~ PATCH_METHOD_REGEX
          patch_name = $1
          instance_variable_set "@#{patch_name}_event_handler", block
          require "tracebin/patches/#{patch_name}"
        else
          super
        end
      end

      def respond_to?(method_sym, include_private = false)
        if method_sym.to_s =~ PATCH_METHOD_REGEX
          true
        else
          super
        end
      end
    end
  end
end
