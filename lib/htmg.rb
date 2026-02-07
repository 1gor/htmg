# frozen_string_literal: true
require_relative "htmg/version"
require "cgi"

module HTMG
  HTML5_TAGS = %i[
    a abbr address area article aside audio b base bdi bdo blockquote body br button canvas caption
    cite code col colgroup data datalist dd del details dfn dialog div dl dt em embed fieldset figcaption
    figure footer form h1 h2 h3 h4 h5 h6 head header hgroup hr html i iframe img input ins kbd label
    legend li link main map mark meta meter nav noscript object ol optgroup option output p param picture
    pre progress q rp rt ruby s samp script section select small source span strong style sub summary sup
    table tbody td template textarea tfoot th thead time title tr track u ul var video wbr
  ].freeze

  def htmg(context = nil, &block)
    Generator.new(context || self).instance_eval(&block).to_s
  end

  def h(string)
    CGI.escapeHTML(string.to_s)
  end

  class Generator
    # Methods that exist in Ruby Object/Kernel but act as HTML tags
    CONFLICTING_TAGS = %i[p select print id class method send open].freeze

    def initialize(context)
      @context = context
    end

    # Explicitly override conflicting methods to forward them to tag logic
    CONFLICTING_TAGS.each do |method_name|
      define_method(method_name) do |*args, **kwargs, &block|
        method_missing(method_name, *args, **kwargs, &block)
      end
    end

    def method_missing(tag_name, *children, **attributes, &block)
      tag = tag_name.to_s.tr("_", "-").to_sym

      # 1. Check if it is a valid tag (HTML5 or Custom)
      if HTMG::HTML5_TAGS.include?(tag) || extra_tags.include?(tag)
        tag(tag, children, attributes, &block)

      # 2. Delegate to parent context if unknown (e.g. helper methods)
      elsif @context.respond_to?(tag_name)
        @context.public_send(tag_name, *children, **attributes, &block)

      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      tag = method_name.to_s.tr("_", "-").to_sym
      HTMG::HTML5_TAGS.include?(tag) ||
      extra_tags.include?(tag) ||
      @context.respond_to?(method_name) || super
    end

    private

    def tag(name, children, attributes, &block)
      # --- Attributes ---
      attrs = attributes.map do |k, v|
        val = if v == true
                k # Boolean attribute (e.g. checked)
              elsif %w[class id].include?(k.to_s)
                v.to_s # Don't escape class/id (for Tailwind/[&>button])
              else
                CGI.escapeHTML(v.to_s) # Default: Safety first
              end
        " #{k}=\"#{val}\""
      end.join

      # --- Content ---
      # 1. Variadic Args
      content = children.map(&:to_s).join

      # 2. Block (with auto-join for Arrays)
      if block_given?
        block_result = instance_eval(&block)
        content << (block_result.is_a?(Array) ? block_result.join : block_result.to_s)
      end

      # --- Render ---
      if content.empty?
        "<#{name}#{attrs} />"
      else
        "<#{name}#{attrs}>#{content}</#{name}>"
      end
    end

    def extra_tags
      @extra_tags ||= begin
        env = ENV["HTMG_EXTRA_TAGS"]&.split(",")&.map(&:strip)&.map(&:to_sym) || []
        env + (defined?(HTMG::EXTRA_TAGS) ? HTMG::EXTRA_TAGS : [])
      end
    end
  end
end
