# HTMG

**Functional HTML generation for Ruby.**

HTMG treats HTML as data structures, not text files. Build stateless, testable, reusable UI components through functional composition—no templating language tax.

## Philosophy: The "MatzLisp" Way

Templates (ERB, Slim) separate logic from structure, often leading to "magic" context and implicit dependencies. HTMG takes a different approach: **Your view is just a function.**

* **Code is Data:** HTML structure is defined by nesting Ruby function calls.
* **Unidirectional Data Flow:** Data is passed explicitly. Views never "pull" data.
* **Explicit over Implicit:** No magical `scope` or `instance_variables`. If a view needs data, it must be passed as an argument.
* **Boring Technology:** Just Ruby. No parsers, no distinct compilation step.

## Installation

```ruby
gem 'htmg'
```

## The ARGS Style

HTMG uses **ARGS style** for all HTML generation. Content and child elements are passed as positional arguments, attributes as keyword arguments.

```ruby
# <div class="card"><h1>Title</h1></div>
div(h1("Title"), class: "card")

# Nested structure
html(
  head(
    meta(charset: "utf-8"),
    title("My App")
  ),
  body(
    header("Welcome"),
    main(p("Hello world"), id: "content"),
    footer("© 2024")
  )
)
```

**Why ARGS style?**
* Cleaner and more readable
* Faster performance (no `instance_eval` overhead)
* Natural functional composition
* Children are auto-joined—no need for `+` operator

**When is `+` needed?** Only when you have multiple top-level siblings that cannot be nested:

```ruby
# Rare: multiple top-level siblings
htmg do
  div("a") + div("b")  # Must use + here
end

# Preferred: nest them instead
htmg do
  div(div("a"), div("b"))  # Auto-joined, no + needed
end
```

### Attribute Syntax

```ruby
# Attributes as keyword arguments
a("Home", href: "/", class: "nav-link")

# Data attributes
div("data-id": "123", "data-type": "user")

# Boolean attributes
input(type: "checkbox", checked: true)
```

### Collections

Use standard Ruby `.map` and `.join`:

```ruby
ul(
  items.map { |i| li(h(i.name)) }.join,
  class: "list"
)
```

### Conditionals

Ruby's ternary or `if` expressions:

```ruby
div(
  active ? "Active" : "Inactive",
  class: active ? "badge-success" : "badge-secondary"
)
```

## Architectural Guide

HTMG is designed for **unidirectional data flow**. Data is fetched once in the route, then flows down through function arguments.

```
Route (fetch data) → Layout (document shell) → Page (compose) → Component (render)
```

Every layer follows the same pattern: a module with `extend self` and `include HTMG`. Pure functions — data in, HTML string out.

### 1. Components — Single UI Elements

Components are the smallest unit. They receive data as keyword arguments and return an HTML string. **Never fetch data inside components.**

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

Components can be nested in subdirectories for grouping (e.g. `views/components/headers/simple.rb` → `Components::Headers::Simple`).

### 2. Pages — Compose Components for a Route

Pages compose components into a full page body. They receive explicit keyword arguments — no framework context needed.

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

Pages don't need `include HTMG` themselves — they just call component `.render` methods and concatenate results with `+`.

### 3. Layouts — Document Shell

Layouts wrap page content in the HTML document structure (`<html>`, `<head>`, `<body>`, header, footer). They receive `ctx` (the app context) because they need request-level information like the current path.

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

Multiple layouts are natural — e.g. an `Error` layout without header/footer for error pages.

### 4. The Route — Fetch Data, Wire Layers

The route is the only place data is fetched. A thin `render_page` helper wires flash messages into the layout.

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

### 5. Summary

| Layer | Receives | Returns | Needs `ctx`? |
|-------|----------|---------|--------------|
| **Component** | Data as keyword args | HTML string | No |
| **Page** | Data as keyword args | HTML string (composed components) | No |
| **Layout** | `ctx`, title, flash, `&block` | Full HTML document | Yes |
| **Route** | Request | Response (via `render_page`) | Is `ctx` |

```ruby
# Components: data only
Components::PostList.render(posts: posts)

# Pages: compose components, data only
Pages::Home.render(user: user, posts: posts)

# Layout: wraps page content in document shell
render_page(title: "Home") { Pages::Home.render(user: user, posts: posts) }
```

## Safety & Escaping

* **Attributes:** Auto-escaped (except `class`/`id` for Tailwind compatibility).
* **Content:** Raw by default. **You must escape user input with `h()`**.

```ruby
div(user_content)      # Renders as-is (potentially unsafe)
div(h(user_content))   # HTML escaped (safe)
```

## HTMX / Reactive Pattern

HTMG shines with "HTML over the Wire" (HTMX, Hotwire). Because components are pure functions, you can reuse them for both full-page renders and partial updates.

```ruby
# Component — same function serves both contexts
module Views
  module Components
    module AlertFeed
      extend self
      include HTMG

      def render(alerts:)
        htmg do
          div(
            alerts.map { |a| div(h(a.msg), class: "p-4 bg-yellow-50 rounded") }.join,
            id: "feed"
          )
        end
      end
    end
  end
end
```

```ruby
# Full page render — component wrapped in layout
r.root do
  alerts = Repo::Alerts.recent
  render_page(title: "Alert Feed") do
    Components::AlertFeed.render(alerts: alerts)
  end
end

# HTMX partial — call the component directly
r.get "partials/feed" do
  Components::AlertFeed.render(alerts: Repo::Alerts.recent)
end
```

This works because:
* Same component renders for both initial page load and HTMX updates
* No duplicated logic between full-page and partial responses
* Components are pure functions — call them anywhere with the same data

## Best Practices

| Category | Do | Don't |
|----------|----|----|
| **Style** | Use ARGS style: `div(h1("Title"), class: "card")` | Use `+` when you could nest instead |
| **State** | Pass data as explicit keyword arguments | Rely on `scope` or instance variables |
| **Layers** | Route → Layout → Page → Component | Skip layers or fetch data in pages/components |
| **Context** | Only layouts receive `ctx` | Pass `ctx` through pages and components |
| **Safety** | Use `h()` for dynamic content | Interpolate strings blindly |
| **HTMX** | Call components directly for partials | Wrap in unnecessary helpers |

## API Reference

### `htmg(context = nil, &block)`

Main entry point. Returns HTML string.

```ruby
ctx.htmg do
  div("Hello", class: "greeting")
end
# => '<div class="greeting">Hello</div>'
```

### Tag Methods

All HTML5 tags are available as methods:

```ruby
tag_name(*content, **attributes)
```

* `*content` - Child elements or text (concatenated)
* `**attributes` - HTML attributes (keyword arguments)

```ruby
div("text", " more", class: "box", id: "main")
# => '<div class="box" id="main">text more</div>'

div(h1("Title"), p("Body"))
# => '<div><h1>Title</h1><p>Body</p></div>'
```

### `h(text)`

HTML escape helper. **Always use for user input.**

```ruby
h("<script>") # => "&lt;script&gt;"
```

## Performance

HTMG bypasses template parsing, running at Ruby method call speed. The ARGS style is faster than block style (no `instance_eval` overhead). Generally comparable to cached ERB.

## License

MIT
