# frozen_string_literal: true

require "spec_helper"

RSpec.describe HTMG do
  include HTMG

  describe "HTMG Generator" do
    it "generates opening and closing tags when a block is provided" do
      output = htmg { div { "Content" } }
      expect(output).to eq("<div>Content</div>")
    end

    it "generates self-closing tags when no block is provided" do
      output = htmg { br }
      expect(output).to eq("<br />")  # Self-closing by default
    end

    it "adds attributes to tags" do
      output = htmg { a(href: "http://example.com") { "Link" } }
      expect(output).to eq('<a href="http://example.com">Link</a>')
    end

    it "escapes special characters in attributes" do
      output = htmg { img(src: "image?name=foo&value=bar") }
      expect(output).to eq('<img src="image?name=foo&amp;value=bar" />')  # Self-closing img tag
    end

    it "handles self-closing tags that are nested" do
      output = htmg { span { img(src: "image?name=foo&value=bar") } }
      expect(output).to eq('<span><img src="image?name=foo&amp;value=bar" /></span>')  # Self-closing img tag
    end


    it "allows custom tags" do
      output = htmg { custom_tag { "Custom Content" } }
      expect(output).to eq("<custom_tag>Custom Content</custom_tag>")
    end

    it "allows nested tags" do
      output = htmg { div { span { "Custom Content"} } }
      expect(output).to eq("<div><span>Custom Content</span></div>")
    end

    it "allows unescaped contant by default" do
      output = htmg do
        p { "<Hello & Welcome>" }
      end
      expect(output).to eq("<p><Hello & Welcome></p>")
    end

    it "allows escaping special characters in content" do
      output = htmg { p { CGI.escapeHTML("<Hello & Welcome>") } }
      expect(output).to eq("<p>&lt;Hello &amp; Welcome&gt;</p>")
    end


    it "handles special characters in attribute keys" do
      output = htmg { div { span("data-my:attr-key": "foo") { "content" } } }
      expect(output).to eq(%(<div><span data-my:attr-key="foo">content</span></div>))
    end

    it "handles special characters in attribute values" do
      output = htmg { div(class: "bg-blue-500 hover:bg-blue-700 focus:ring-4 focus:ring-blue-300 focus:ring-opacity-50") { "content" } }
      expect(output).to eq(%(<div class="bg-blue-500 hover:bg-blue-700 focus:ring-4 focus:ring-blue-300 focus:ring-opacity-50">content</div>))
    end

    it "handles complex TailwindCSS class values with special characters" do
      output = htmg { div(class: "sm:bg-green-100 lg:hover:bg-green-500 [&>button]:text-white") { "content" } }
      expect(output).to eq(%(<div class="sm:bg-green-100 lg:hover:bg-green-500 [&>button]:text-white">content</div>))
    end
  end
end
