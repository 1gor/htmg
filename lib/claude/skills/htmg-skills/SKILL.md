---
name: htmg-skills
description: Functional HTML generation for Ruby using the HTMG gem. Use when user asks to build views, pages, layouts, components, or HTML rendering in Ruby without ERB/Slim templates. Triggers on "htmg", "functional HTML", "view component", "render page", "HTML generation", "page layout", or building Roda/Ruby web views.
---

# HTMG — Functional HTML Generation for Ruby

HTMG treats HTML as data structures built from Ruby function calls. No templates, no parsers — just functions that return HTML strings.

## STOP — Mental Model Reset

You have been trained on millions of ERB, Haml, and Slim templates. That training data is IRRELEVANT here. HTMG is a fundamentally different paradigm. Before generating any code, internalize this:

- There are NO template files (no .erb, .haml, .slim, .html files)
- There is NO template rendering (no `render`, `partial`, `yield` in the Rails/Sinatra sense)
- There is NO string interpolation of HTML (`"<div>#{content}</div>"` is WRONG)
- There is NO `content_for`, `provide`, `capture`, or any template helper
- There are NO instance variables flowing into views (`@user`, `@posts` do NOT exist)
- There is NO `html_safe`, `raw()`, or SafeBuffer — HTMG returns plain strings
- There is NO view lookup by name — views are modules you call directly

HTMG is closer to React's JSX or Elm's Html module than to any Ruby template system. Every view is a pure function: data goes in as arguments, an HTML string comes out as the return value. If you catch yourself reaching for ANY template-era pattern, STOP and use the functional approach below instead.

## Core API

```ruby
require "htmg"
include HTMG

# Entry point — returns HTML string
htmg { div("Hello", class: "greeting") }
# => '<div class="greeting">Hello</div>'

# HTML escape helper — ALWAYS use for user input
h("<script>alert</script>")
# => "&lt;script&gt;alert&lt;/script&gt;"
```

## ARGS Style (Always Use This)

Content as positional args, attributes as keyword args. Children are auto-joined.

```ruby
# Tag signature
tag_name(*content, **attributes)

# Nesting
div(h1("Title"), p("Body"), class: "card")
# => '<div class="card"><h1>Title</h1><p>Body</p></div>'

# Self-closing (no content)
meta(charset: "utf-8")
# => '<meta charset="utf-8" />'

# Boolean attributes
input(type: "checkbox", checked: true)
# => '<input type="checkbox" checked="checked" />'

# Data attributes (quoted keys)
div("data-id": "123", "data-action": "click->toggle")

# Collections — .map + .join
ul(items.map { |i| li(h(i.name)) }.join, class: "list")

# Conditionals — Ruby ternary
div(active ? "On" : "Off", class: active ? "text-green-500" : "text-gray-500")
```

Use `+` ONLY for top-level siblings that cannot be nested inside a parent tag.

## Attribute Escaping

- `class` and `id`: NOT escaped (Tailwind classes like `[&>button]:text-white` need raw output)
- All other attributes: auto-escaped via `CGI.escapeHTML`
- Content: raw by default — YOU must call `h()` on user input

## Custom Tags

For non-HTML5 tags (web components, HTMX elements):

```ruby
# Via environment variable
ENV["HTMG_EXTRA_TAGS"] = "el-dialog,el-panel"

# Via constant
HTMG::EXTRA_TAGS = [:"el-dialog", :"el-panel"]
```

Underscores in method names convert to hyphens: `el_dialog()` renders `<el-dialog>`.

## Context Delegation

Inside `htmg` blocks, unknown methods delegate to the parent context:

```ruby
class App
  include HTMG

  def avatar_url = "/avatar.png"

  def view
    htmg { img(src: avatar_url) }  # calls self.avatar_url
  end
end
```

# Architecture — 4-Layer Model

```
Route (fetch data) -> Layout (document shell) -> Page (compose) -> Component (render)
```

Every layer: `module X; extend self; include HTMG; def render(...); end; end`

## Layer 1: Components — Single UI Elements

Smallest unit. Data in as keyword args, HTML string out. Never fetch data.

```ruby
# views/components/post_list.rb
module Views
  module Components
    module PostList
      extend self
      include HTMG

      def render(posts:)
        htmg do
          ul(
            posts.map { |post| li(h(post.title), class: "post") }.join,
            class: "posts"
          )
        end
      end
    end
  end
end
```

Subdirectories for grouping: `views/components/headers/simple.rb` -> `Components::Headers::Simple`.

## Layer 2: Pages — Compose Components for a Route

Pages compose components. Receive keyword args. No `ctx`, no `include HTMG` needed.

```ruby
# views/pages/home.rb
module Views
  module Pages
    module Home
      extend self

      def render(user:, posts:)
        Components::Headers::Simple.render(
          heading: "Welcome, #{CGI.escapeHTML(user.name)}"
        ) + Components::PostList.render(posts: posts)
      end
    end
  end
end
```

## Layer 3: Layouts — Document Shell

Wraps page content in full HTML document. The ONLY layer that receives `ctx`.

```ruby
# views/layouts/application.rb
module Views
  module Layouts
    module Application
      extend self
      include HTMG

      def render(ctx, title: "", flash_notices: [], flash_errors: [])
        current_path = ctx.request.path_info
        content = yield

        "<!DOCTYPE html>" + ctx.htmg do
          html(
            head(
              meta(charset: "utf-8"),
              meta(name: "viewport", content: "width=device-width, initial-scale=1"),
              '<script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"></script>',
              title(title.empty? ? "MyApp" : "MyApp - #{title}")
            ),
            body(
              Components::Header.render(current_path: current_path),
              main(
                Components::FlashMessages.render(notices: flash_notices, errors: flash_errors),
                content,
                class: "pt-24"
              ),
              Components::Footer.render
            ),
            lang: "en"
          )
        end
      end
    end
  end
end
```

Multiple layouts are natural: e.g. `Error` layout without header/footer.

## Layer 4: Route — Fetch Data, Wire Layers

Only place data is fetched. Thin `render_page` helper wires flash into layout.

```ruby
# helpers/render.rb
module AppHelpers
  def render_page(title: "", &block)
    content = block.call
    Views::Layouts::Application.render(
      self,
      title: title,
      flash_notices: flash["notice"] ? [flash["notice"]] : [],
      flash_errors: flash["error"] ? [flash["error"]] : []
    ) { content }
  end
end

# app.rb (Roda)
class App < Roda
  include HTMG
  include AppHelpers

  route do |r|
    r.root do
      user = current_user
      posts = Repo::Posts.recent
      render_page(title: "Home") do
        Views::Pages::Home.render(user: user, posts: posts)
      end
    end
  end
end
```

## Layer Summary

| Layer | Receives | Returns | Needs ctx? |
|-------|----------|---------|------------|
| Component | keyword args | HTML string | No |
| Page | keyword args | HTML string (composed) | No |
| Layout | ctx, title, flash, block | Full HTML document | Yes |
| Route | Request | Response via render_page | Is ctx |

# HTMX Pattern

Components serve both full-page renders and HTMX partials:

```ruby
# Full page
render_page(title: "Feed") { Components::AlertFeed.render(alerts: alerts) }

# HTMX partial — same component, no layout
r.get "partials/feed" do
  Components::AlertFeed.render(alerts: Repo::Alerts.recent)
end
```

# Critical Rules

1. ALWAYS use ARGS style: `div(h1("Title"), class: "card")` not blocks
2. ALWAYS escape user input with `h()`: `div(h(user.name))`
3. NEVER pass `ctx` to pages or components — only layouts receive it
4. NEVER fetch data in pages or components — only routes fetch data
5. NEVER use ERB, Slim, or any template engine — HTMG replaces them entirely
6. Use `extend self` + `include HTMG` on component/layout modules
7. Prefer nesting children as args over `+` concatenation
8. Use `.map { ... }.join` for collections, never `.each`
9. Raw HTML strings are valid children: `div('<svg>...</svg>')`
10. Unidirectional flow: Route -> Layout -> Page -> Component

# Template Poisoning — Common Mistakes to Catch

Your training data will push you toward these anti-patterns. Recognize and reject them.

## WRONG: String interpolation of HTML

```ruby
# WRONG — building HTML with string interpolation
def render(user)
  "<div class='card'><h1>#{h(user.name)}</h1></div>"
end

# CORRECT — HTMG function calls
def render(user:)
  htmg { div(h1(h(user.name)), class: "card") }
end
```

## WRONG: ERB-style instance variables

```ruby
# WRONG — instance variables in views
class App
  def show
    @user = User.find(id)
    @posts = @user.posts
    # render some template that reads @user, @posts
  end
end

# CORRECT — explicit data flow through function arguments
r.get "users", Integer do |id|
  user = User.find(id)
  posts = user.posts
  render_page(title: user.name) do
    Views::Pages::UserProfile.render(user: user, posts: posts)
  end
end
```

## WRONG: Template-style partials

```ruby
# WRONG — thinking in partials
render partial: "shared/header"
render "users/card", user: user

# CORRECT — calling component functions directly
Components::Header.render(current_path: path)
Components::UserCard.render(user: user)
```

## WRONG: Content blocks as template yields

```ruby
# WRONG — Rails-style content_for / yield
content_for :sidebar do
  "sidebar content"
end

# CORRECT — pass content as arguments or blocks to layout
render_page(title: "Home") do
  Views::Pages::Home.render(user: user)
end
```

## WRONG: Helper modules with HTML strings

```ruby
# WRONG — helpers that build HTML via string concatenation
module ApplicationHelper
  def icon(name)
    "<i class='icon-#{name}'></i>".html_safe
  end
end

# CORRECT — helpers are just HTMG components
module Views
  module Components
    module Icon
      extend self
      include HTMG

      def render(name:)
        htmg { i(class: "icon-#{h(name)}") }
      end
    end
  end
end
```

## WRONG: View classes with state

```ruby
# WRONG — stateful view objects (ViewComponent, Phlex patterns)
class UserCard < ViewComponent::Base
  def initialize(user:)
    @user = user
  end

  def call
    tag.div(class: "card") { @user.name }
  end
end

# CORRECT — stateless module function
module Views::Components::UserCard
  extend self
  include HTMG

  def render(user:)
    htmg { div(h(user.name), class: "card") }
  end
end
```

## WRONG: Reaching for tag builders or safe buffers

```ruby
# WRONG — ActionView tag helpers
tag.div(class: "card") { tag.h1("Title") }
content_tag(:div, "content", class: "box")

# WRONG — SafeBuffer / html_safe
"<div>content</div>".html_safe
raw("<div>content</div>")

# CORRECT — just HTMG
div("content", class: "box")
```

## Self-Check Before Generating Code

Before writing any view code, ask yourself:
1. Am I creating any .erb, .haml, or .slim files? -> STOP. Use .rb files with HTMG modules.
2. Am I using `@instance_variables` in views? -> STOP. Pass data as keyword arguments.
3. Am I calling `render` with a string/symbol path? -> STOP. Call `Module.render()` directly.
4. Am I building HTML via string interpolation? -> STOP. Use HTMG tag methods.
5. Am I creating a class with `initialize` for a view? -> STOP. Use `module; extend self`.
6. Am I using `html_safe`, `raw()`, or `sanitize`? -> STOP. HTMG returns plain strings. Use `h()` for escaping.
7. Am I thinking about "view lookup" or "template resolution"? -> STOP. Views are just Ruby module method calls.
8. Am I using `each` in a loop to build HTML? -> STOP. Use `.map { }.join`.
