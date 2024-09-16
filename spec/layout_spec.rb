# frozen_string_literal: true

require_relative "layout_helper"

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
      page = layout(title: title)
      expected = %(<html><head><meta title="My article title" /></head><body><header><ul class="nav"><li>menu foo</li><li>menu bar</li></ul></header><main><h1 class="article-title">My article title</h1><div class="text-black">Contents of the first article</div></main></body></html>)
      expect(page).to eq(expected)
    end
  end
end
