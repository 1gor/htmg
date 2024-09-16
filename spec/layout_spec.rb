# frozen_string_literal: true

module LayoutHelper
  include HTMG

  # Define the layout as a method that accepts title, header, and content
  def layout(title:, header:, content:)
    htmg do
      html do
        head { meta(title: title) } + body { header { header } + main { content } }
      end
    end
  end

  # Helper to define the header section
  def header
    htmg do
      ul(class: "nav") {
        [:foo, :bar].map { |n| li { "menu #{n}" } }.join
      }
    end
  end

  # Helper to define the content section
  def content(title)
    htmg do
      h1(class: "article-title") { title } +
      div(class: "text-black") { "Contents of the first article" }
    end
  end
end

RSpec.describe "Advanced Page Layout Usage" do
  include LayoutHelper

  let(:title) { "My article title" }

  context "when constructing a full page" do
    it "generates the correct header" do
      output = header
      expected = %(<ul class="nav"><li>menu foo</li><li>menu bar</li></ul>)
      expect(output).to eq(expected)
    end

    it "generates the correct content" do
      output = content(title)
      expected = %(<h1 class="article-title">My article title</h1><div class="text-black">Contents of the first article</div>)
      expect(output).to eq(expected)
    end

    it "generates the correct layout with header and content" do
      page = layout(
        title: title,
        header: header,
        content: content(title)
      )
      expected = %(<html><head><meta title="My article title" /></head><body><header><ul class="nav"><li>menu foo</li><li>menu bar</li></ul></header><main><h1 class="article-title">My article title</h1><div class="text-black">Contents of the first article</div></main></body></html>)
      expect(page).to eq(expected)
    end
  end
end
