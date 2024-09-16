# frozen_string_literal: true

require "erb"

module LayoutHelperERB
  def layout_erb(title:, header:, content:)
    template = <<-ERB
    <html>
        <head>
            <meta title="<%= title %>" />
        </head>
        <body>
            <header>
                <%= header %>
            </header>
            <main>
                <%= content %>
            </main>
        </body>
    </html>
    ERB

    ERB.new(template).result(binding)
  end

  def header_erb
    ERB.new(<<~ERB).result(binding)
      <ul class="nav">
          <li>menu foo</li>
          <li>menu bar</li>
      </ul>
    ERB
  end

  def content_erb(title)
    template = <<-ERB
        <h1 class="article-title"><%= title %></h1>
        <div class="text-black">
            Contents of the first article
        </div>
    ERB

    ERB.new(template).result(binding)
  end
end
