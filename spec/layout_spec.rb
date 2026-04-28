# frozen_string_literal: true

require "spec_helper"

# --- Components: smallest unit, data in → HTML out ---

module TestViews
  module Components
    module Nav
      extend self
      include HTMG

      def render(items:)
        htmg do
          ul(
            items.map { |n| li(h(n.to_s)) }.join,
            class: "nav"
          )
        end
      end
    end

    module Article
      extend self
      include HTMG

      def render(title:, body:)
        htmg do
          h1(h(title), class: "article-title") +
            div(h(body), class: "text-black")
        end
      end
    end
  end

  # --- Page: composes components, no ctx needed ---

  module Pages
    module Home
      extend self

      def render(title:, body:)
        Components::Article.render(title: title, body: body)
      end
    end
  end

  # --- Layout: document shell, receives ctx ---

  module Layouts
    module Application
      extend self
      include HTMG

      def render(ctx, title:, nav_items: [])
        content = yield

        ctx.htmg do
          html(
            head(meta(charset: "utf-8"), title(title)),
            body(
              header(Components::Nav.render(items: nav_items)),
              main(content)
            )
          )
        end
      end
    end
  end
end

# --- Specs ---

RSpec.describe "Page Layout Architecture" do
  include HTMG

  describe "Components" do
    it "Nav renders a list of items" do
      output = TestViews::Components::Nav.render(items: [:foo, :bar])
      expect(output).to eq(%(<ul class="nav"><li>foo</li><li>bar</li></ul>))
    end

    it "Article renders title and body" do
      output = TestViews::Components::Article.render(title: "Hello", body: "World")
      expect(output).to eq(%(<h1 class="article-title">Hello</h1><div class="text-black">World</div>))
    end

    it "escapes user content" do
      output = TestViews::Components::Article.render(title: "<script>", body: "safe")
      expect(output).to include("&lt;script&gt;")
    end
  end

  describe "Pages" do
    it "composes components" do
      output = TestViews::Pages::Home.render(title: "My Title", body: "My Body")
      expect(output).to include(%(<h1 class="article-title">My Title</h1>))
      expect(output).to include(%(<div class="text-black">My Body</div>))
    end
  end

  describe "Layouts" do
    it "wraps page content in a full document" do
      ctx = self
      page = TestViews::Layouts::Application.render(ctx, title: "Test", nav_items: [:home, :about]) do
        TestViews::Pages::Home.render(title: "Welcome", body: "Content here")
      end

      expect(page).to include("<html>")
      expect(page).to include("<title>Test</title>")
      expect(page).to include(%(<ul class="nav"><li>home</li><li>about</li></ul>))
      expect(page).to include(%(<h1 class="article-title">Welcome</h1>))
      expect(page).to include("</html>")
    end

    it "separates layout concerns from page concerns" do
      ctx = self
      page = TestViews::Layouts::Application.render(ctx, title: "Empty", nav_items: []) do
        "raw content"
      end

      expect(page).to include("<main>raw content</main>")
      # Empty non-void elements render with an explicit closing tag (HTML5
       # browsers treat self-closing syntax on non-void elements as an
       # unclosed opening tag, breaking sibling layout).
      expect(page).to include(%(<ul class="nav"></ul>))
    end
  end
end
