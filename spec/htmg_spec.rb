# frozen_string_literal: true

require "spec_helper"

RSpec.describe HTMG do
  include HTMG

  describe "HTMG Generator" do
    it "generates opening and closing tags" do
      # Argument style
      expect(htmg { div("Content") }).to eq("<div>Content</div>")
      # Block style
      expect(htmg { div { "Content" } }).to eq("<div>Content</div>")
    end

    it "self-closes void HTML elements when empty" do
      expect(htmg { br }).to eq("<br />")
      expect(htmg { hr }).to eq("<hr />")
      expect(htmg { img(src: "x.png") }).to eq('<img src="x.png" />')
      expect(htmg { meta(charset: "utf-8") }).to eq('<meta charset="utf-8" />')
    end

    it "uses an explicit closing tag for empty non-void elements" do
      # Browsers don't honour XML self-closing on non-void HTML elements:
      # "<div />" is parsed as an unclosed opening tag, so subsequent siblings
      # nest inside it. Empty non-void elements MUST render as "<tag></tag>".
      expect(htmg { div(class: "spacer") }).to eq('<div class="spacer"></div>')
      expect(htmg { span("aria-hidden": "true") }).to eq('<span aria-hidden="true"></span>')
      expect(htmg { section }).to eq("<section></section>")
    end

    it "preserves sibling order when an empty non-void element sits between content" do
      # Regression: previously "<div />" caused sibling content to nest inside
      # the empty div on real browsers, breaking layouts. Order must be flat.
      output = htmg do
        div(
          span("a"),
          div(class: "separator"),
          span("b"),
          class: "wrapper"
        )
      end
      expect(output).to eq(
        '<div class="wrapper"><span>a</span><div class="separator"></div><span>b</span></div>'
      )
    end

    it "adds attributes to tags" do
      # Argument style
      expect(htmg { a("Link", href: "http://example.com") }).to eq('<a href="http://example.com">Link</a>')
      # Block style
      expect(htmg { a(href: "http://example.com") { "Link" } }).to eq('<a href="http://example.com">Link</a>')
    end

    it "escapes special characters in attributes" do
      output = htmg { img(src: "image?name=foo&value=bar") }
      expect(output).to eq('<img src="image?name=foo&amp;value=bar" />')
    end

    it "handles self-closing tags that are nested" do
      # Argument style
      expect(htmg { span(img(src: "image?name=foo&value=bar")) }).to eq('<span><img src="image?name=foo&amp;value=bar" /></span>')
      # Block style
      expect(htmg { span { img(src: "image?name=foo&value=bar") } }).to eq('<span><img src="image?name=foo&amp;value=bar" /></span>')
    end

    it "allows nested tags" do
      # Argument style
      expect(htmg { div(span("Custom Content")) }).to eq("<div><span>Custom Content</span></div>")
      # Block style
      expect(htmg { div { span { "Custom Content" } } }).to eq("<div><span>Custom Content</span></div>")
      # Mixed style (Block outer, Argument inner)
      expect(htmg { div { span("Custom Content") } }).to eq("<div><span>Custom Content</span></div>")
    end

    it "allows unescaped content by default" do
      # Argument style
      expect(htmg { p("<Hello & Welcome>") }).to eq("<p><Hello & Welcome></p>")
      # Block style
      expect(htmg { p { "<Hello & Welcome>" } }).to eq("<p><Hello & Welcome></p>")
    end

    it "allows escaping special characters in content" do
      # Argument style
      expect(htmg { p(h("<Hello & Welcome>")) }).to eq("<p>&lt;Hello &amp; Welcome&gt;</p>")
      # Block style
      expect(htmg { p { h("<Hello & Welcome>") } }).to eq("<p>&lt;Hello &amp; Welcome&gt;</p>")
    end

    it "handles special characters in attribute keys" do
      # Argument style
      expect(htmg { div(span("content", "data-my:attr-key": "foo")) }).to eq(%(<div><span data-my:attr-key="foo">content</span></div>))
      # Block style
      expect(htmg { div { span("data-my:attr-key": "foo") { "content" } } }).to eq(%(<div><span data-my:attr-key="foo">content</span></div>))
    end

    it "handles special characters in attribute values" do
      classes = "bg-blue-500 hover:bg-blue-700 focus:ring-4 focus:ring-blue-300 focus:ring-opacity-50"
      expected = %(<div class="#{classes}">content</div>)

      # Argument style
      expect(htmg { div("content", class: classes) }).to eq(expected)
      # Block style
      expect(htmg { div(class: classes) { "content" } }).to eq(expected)
    end

    it "handles complex TailwindCSS class values with special characters" do
      classes = "sm:bg-green-100 lg:hover:bg-green-500 [&>button]:text-white"
      expected = %(<div class="#{classes}">content</div>)

      # Argument style
      expect(htmg { div("content", class: classes) }).to eq(expected)
      # Block style
      expect(htmg { div(class: classes) { "content" } }).to eq(expected)
    end
  end

  describe "HTML5 tags validation" do
    it "allows valid HTML5 tags" do
      # Argument style
      expect(htmg { div("Content") }).to eq("<div>Content</div>")
      # Block style
      expect(htmg { div { "Content" } }).to eq("<div>Content</div>")
    end

    it "raises NoMethodError for invalid HTML5 tags" do
      # Argument style
      expect { htmg { invalid_tag("Content") } }.to raise_error(NoMethodError)
      # Block style
      expect { htmg { invalid_tag { "Content" } } }.to raise_error(NoMethodError)
    end

    it "supports custom tags through environment variable" do
      ENV["HTMG_EXTRA_TAGS"] = "foo,bar"

      # Argument style
      expect(htmg { foo("Custom Content") }).to eq("<foo>Custom Content</foo>")
      # Block style
      expect(htmg { foo { "Custom Content" } }).to eq("<foo>Custom Content</foo>")
    ensure
      ENV["HTMG_EXTRA_TAGS"] = nil
    end

    it "does not allow custom tags if not specified in environment" do
      ENV["HTMG_EXTRA_TAGS"] = nil
      # Argument style
      expect { htmg { foo("Content") } }.to raise_error(NoMethodError)
      # Block style
      expect { htmg { foo { "Content" } } }.to raise_error(NoMethodError)
    end

    it "handles tags in the EXTRA_TAGS constant" do
      stub_const("HTMG::EXTRA_TAGS", [:custom1, :custom2])

      # Argument style
      expect(htmg { custom1("Custom Content") }).to eq("<custom1>Custom Content</custom1>")
      # Block style
      expect(htmg { custom1 { "Custom Content" } }).to eq("<custom1>Custom Content</custom1>")
    end

    it "supports both environment variable and EXTRA_TAGS" do
      ENV["HTMG_EXTRA_TAGS"] = "foo"
      stub_const("HTMG::EXTRA_TAGS", [:bar])
      expected = "<foo>Foo Content</foo><bar>Bar Content</bar>"

      # Argument style (String concatenation)
      output_args = htmg do
        foo("Foo Content") + bar("Bar Content")
      end
      expect(output_args).to eq(expected)

      # Block style (String concatenation)
      output_block = htmg do
        foo { "Foo Content" } + bar { "Bar Content" }
      end
      expect(output_block).to eq(expected)
    ensure
      ENV["HTMG_EXTRA_TAGS"] = nil
    end
  end
end
