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

HTMG is designed for **unidirectional data flow**. Data is fetched once in the route, then flows down through function arguments to views and components.

```
Route (fetch data) → View (compose) → Component (render)
```

### 1. The Route is the Composer

The route fetches data and coordinates views. It passes context (`self`) and data explicitly.

```ruby
# app.rb (Roda)
route do |r|
  r.root do
    # FETCH DATA HERE (only place data is fetched)
    user = current_user
    posts = Repo::Posts.recent

    # PASS DATA DOWN
    HTMGHelpers.render_page(self, title: "Home") do
      Views.home(self, user: user, posts: posts)
    end
  end
end
```

### 2. Views are Pure Functions

Views are modules with stateless methods. They receive `ctx` (the app context) and explicit keyword arguments.

```ruby
# views.rb
module Views
  extend self
  include HTMG

  def home(ctx, user:, posts:)
    ctx.htmg do
      div(
        h1("Welcome, #{h(user.name)}"),
        Components.post_list(posts: posts),
        class: "container"
      )
    end
  end
end
```

### 3. Components are Pure Functions

Components receive data, return HTML. **Never fetch data inside components**—receive everything as parameters.

```ruby
# components.rb
module Components
  extend self
  include HTMG

  # Data comes in as parameters, HTML goes out
  def post_list(posts:)
    htmg do
      ul(
        posts.map { |post| li(h(post.title), class: "post") }.join,
        class: "posts"
      )
    end
  end
end
```

### 4. Layouts with HTMGHelpers

Create a helpers module with `render_page` for consistent HTML document layout:

```ruby
# htmg_helpers.rb
module HTMGHelpers
  extend self
  include HTMG

  # The ONLY essential helper - wraps content in HTML document structure
  def render_page(ctx, title: "App", &content)
    ctx.htmg do
      html(
        head(
          meta(charset: "utf-8"),
          meta(name: "viewport", content: "width=device-width, initial-scale=1"),
          title(title),
          css_bootstrap
        ),
        body(
          main(content.call, id: "main-content"),
          js_bootstrap
        )
      )
    end
  end

  # Asset helpers (return raw strings, no htmg needed)
  def css_bootstrap
    '<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet" crossorigin="anonymous">'
  end

  def js_bootstrap
    '<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js" crossorigin="anonymous"></script>'
  end
end
```

Add application-specific helpers (navbar, flash, etc.) as needed—they're just functions.

### 5. Usage Pattern Summary

```ruby
# Views: ctx is first argument, data as keyword args
Views.home(ctx, user: user, posts: posts)

# Components: data only (no ctx unless generating links)
Components.post_list(posts: posts)

# Layout: ctx and title, content via block
HTMGHelpers.render_page(ctx, title: "Home") do
  Views.home(ctx, user: user, posts: posts)
end
```

## Safety & Escaping

* **Attributes:** Auto-escaped (except `class`/`id` for Tailwind compatibility).
* **Content:** Raw by default. **You must escape user input with `h()`**.

```ruby
div(user_content)      # Renders as-is (potentially unsafe)
div(h(user_content))   # HTML escaped (safe)
```

## HTMX / Reactive Pattern

HTMG shines with "HTML over the Wire" (HTMX, Hotwire). Because components are just functions, you can reuse them for both full-page renders and partial updates.

**Routes:**

```ruby
# Full page render
r.root do
  alerts = Repo::Alerts.recent

  HTMGHelpers.render_page(self, title: "Alert Feed") do
    Components.alert_feed(alerts: alerts)
  end
end

# HTMX partial - just call the component directly
r.on "partials" do
  r.get "feed" do
    Components.alert_feed(alerts: Repo::Alerts.recent)
  end
end
```

**Component:**

```ruby
module Components
  extend self
  include HTMG

  def alert_feed(alerts:)
    htmg do
      div(
        alerts.map { |a|
          div(h(a.msg), class: "alert")
        }.join,
        id: "feed"
      )
    end
  end
end
```

This pattern works because:
* Same component renders for both initial page load and HTMX updates
* No duplicated logic between AJAX and full-page responses
* Components are pure functions—call them anywhere with the same data

## Best Practices

| Category | Do | Don't |
|----------|----|----|
| **Style** | Use ARGS style: `div(h1("Title"), class: "card")` | Use `+` when you could nest instead |
| **State** | Pass data as explicit arguments | Rely on `scope` or instance variables |
| **Context** | Pass `ctx` as first argument | Use global helpers or mixins |
| **Logic** | Keep logic in routes/repositories | Fetch data inside views |
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
