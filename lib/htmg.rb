# frozen_string_literal: true

require_relative "htmg/version"
require "cgi"

module HTMG
  class Error < StandardError; end

  # Main method to generate HTML. Generates tags with automatic escaping unless `:raw` is specified.
  def htmg(&block)
    Generator.new.instance_eval(&block)
  end

  class Generator
    # List of HTML tag names that conflict with Ruby methods
    CONFLICTING_TAGS = %i[p select print id class method send open].freeze

    def initialize
    end

    # Handle dynamic tag methods
    def method_missing(tag_name, attributes = {}, &block)
      content = block ? instance_eval(&block) : nil
      gentag(tag_name, attributes, content)
    end

    def respond_to_missing?(*)
      true
    end

    private

    # Generate the HTML tag string
    def gentag(tag_name, attributes, content)
      tag_name = tag_name.to_s

      unless attributes.empty?
        attribs = attributes.map do |k, v|
          # Escape all attributes, except for class and id
          if %w[class id].include?(k.to_s)
            " #{k}=\"#{v}\""
          else
            " #{k}=\"#{CGI.escapeHTML(v.to_s)}\""
          end
        end.join
      end

      if content
        "<#{tag_name}#{attribs}>#{content}</#{tag_name}>"
      else
        "<#{tag_name}#{attribs} />"  # Always self-close when there's no content
      end
    end

    # Escape HTML entities for non-raw content
    def entities(s)
      CGI.escapeHTML(s)
    end

    # Override conflicting methods to forward to method_missing
    CONFLICTING_TAGS.each do |method_name|
      define_method(method_name) do |*args, &block|
        method_missing(method_name, *args, &block)
      end
    end
  end
end
