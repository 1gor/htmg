# frozen_string_literal: true

# Copyright 2011 Salvatore Sanfilippo. All rights reserved.
# Modifications by Igor B. Drozdov, 2024.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#    1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#    2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY SALVATORE SANFILIPPO ''AS IS'' AND ANY EXPRESS
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
# NO EVENT SHALL SALVATORE SANFILIPPO OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# The views and conclusions contained in the software and documentation are
# those of the authors and should not be interpreted as representing official
# policies, either expressed or implied, of Salvatore Sanfilippo or Igor B. Drozdov.

require_relative "htmg/version"
require "cgi"

module HTMG
  # Valid HTML5 tags according to the HTML5 specification
  HTML5_TAGS = %i[
    a abbr address area article aside audio b base bdi bdo blockquote body br button canvas caption
    cite code col colgroup data datalist dd del details dfn dialog div dl dt em embed fieldset figcaption
    figure footer form h1 h2 h3 h4 h5 h6 head header hgroup hr html i iframe img input ins kbd label
    legend li link main map mark meta meter nav noscript object ol optgroup option output p param picture
    pre progress q rp rt ruby s samp script section select small source span strong style sub summary sup
    table tbody td template textarea tfoot th thead time title tr track u ul var video wbr
  ].freeze

  def htmg(...)
    Generator.new.instance_exec(self, ...)
  end

  class Generator
    # List of HTML tag names that conflict with Ruby methods
    CONFLICTING_TAGS = %i[p select print id class method send open].freeze

    def initialize
    end

    # Handle dynamic tag methods
    def method_missing(tag_name, attributes = {}, &block)
      valid_tag = HTMG::HTML5_TAGS.include?(tag_name) || extra_tags.include?(tag_name)

      if valid_tag
        content = block ? instance_eval(&block) : nil
        gentag(tag_name, attributes, content)
      else
        raise NoMethodError, "Invalid HTML tag: #{tag_name}"
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      HTMG::HTML5_TAGS.include?(method_name) || extra_tags.include?(method_name) || super
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

    # Handle extra tags defined in an environment variable or constant
    def extra_tags
      @extra_tags ||= begin
        extra_tags_from_env = ENV["HTMG_EXTRA_TAGS"]&.split(",")&.map(&:strip)&.map(&:to_sym) || []
        extra_tags_from_env + (defined?(HTMG::EXTRA_TAGS) ? HTMG::EXTRA_TAGS : [])
      end
    end

    # Escape HTML entities for non-raw content
    def h(s)
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
