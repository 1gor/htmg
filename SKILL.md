---
name: htmg
description: Generates HTML views for Roda/Sinatra apps using HTMG Ruby library with ARGS style functional composition. Use when user asks to "create a view", "convert ERB to HTMG", "refactor layout", "build a component", or "fix HTML generation" in a Ruby/Roda context. Also use when discussing view patterns, layouts, or HTMX partials.
---

# HTMG View Architect

## Instructions

You build views for Roda/Sinatra apps using HTMG with the "MatzLisp" philosophy: **pure Ruby functions**, **unidirectional data flow**, and **explicit dependencies**.

### Core Principles

1. **Views are Functions**: Accept `ctx` first, then data as keyword arguments. Return HTML strings.
2. **Unidirectional Flow**: Data is fetched in the route, passed down to views. Views NEVER fetch data.
3. **ARGS Style**: Use `div(h1("Title"), class: "card")` - children as positional args, attributes as kwargs.
4. **No Magic**: No `@instance_vars`, no `scope.`, no implicit state. Everything explicit.

---

## The ARGS Style

HTMG uses **ARGS style**. Content and children are positional arguments, attributes are keyword arguments. Children are auto-joined—no `+` operator needed.

```ruby
# Simple element
div("Hello", class: "greeting")
# => '<div class="greeting">Hello</div>'

# Nested elements - children auto-joined
div(
  h1("Title"),
  p("Body"),
  class: "container"
)
# => '<div class="container"><h1>Title</h1><p>Body</p></div>'

# Full document
html(
  head(
    meta(charset: "utf-8"),
    title("My App")
  ),
  body(
    header("Welcome"),
    main(p("Content"), id: "main"),
    footer("© 2024")
  )
)
```

### When is `+` Needed?

Only when you have multiple top-level siblings that cannot be nested:

```ruby
# RARE: truly need + for top-level siblings
htmg do
  div("a") + div("b")
end

# PREFERRED: nest them instead
htmg do
  div(div("a"), div("b"))
end
```

### Collections

Use `.map` and `.join`:

```ruby
ul(
  items.map { |i| li(h(i.name)) }.join,
  class: "list"
)
```

---

## Safety

* **Attributes**: Auto-escaped (except `class`/`id` for Tailwind)
* **Content**: RAW by default. ALWAYS use `h()` for user input

```ruby
# UNSAFE
div(user_input)

# SAFE
div(h(user_input))
```

---

## Architecture Pattern

### Data Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│                      Roda Route                         │
│  ┌─────────────┐                                       │
│  │ FETCH DATA  │  user = current_user                  │
│  │   (ONLY     │  posts = Repo::Posts.recent           │
│  │   HERE)     │                                       │
│  └──────┬──────┘                                       │
└─────────┼───────────────────────────────────────────────┘
          │ data flows down (never up)
          ▼
┌─────────────────────────────────────────────────────────┐
│                   HTMGHelpers.render_page               │
│           (layout wrapper, receives ctx + block)        │
└─────────┼───────────────────────────────────────────────┘
          │ content.call
          ▼
┌─────────────────────────────────────────────────────────┐
│                      Views.home                         │
│         (receives ctx + data, composes structure)       │
└─────────┼───────────────────────────────────────────────┘
          │ posts: posts
          ▼
┌─────────────────────────────────────────────────────────┐
│                Components.post_list                     │
│      (pure function, data in → HTML out, no fetching)   │
└─────────────────────────────────────────────────────────┘
```

**Rule:** Data is fetched ONCE in the route, then flows down through function arguments.

### 1. HTMGHelpers Module (Layout)

Create ONE helper module with `render_page` for consistent HTML documents:

```ruby
# htmg_helpers.rb
module HTMGHelpers
  extend self
  include HTMG

  # The ONLY essential helper
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

  # Asset helpers return raw strings
  def css_bootstrap
    '<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet" crossorigin="anonymous">'
  end

  def js_bootstrap
    '<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js" crossorigin="anonymous"></script>'
  end
end
```

### 2. Views (Page Composition)

Views receive `ctx` and data, compose the page structure:

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

### 3. Components (Pure Functions)

Components receive data, return HTML. NEVER fetch data inside:

```ruby
# components.rb
module Components
  extend self
  include HTMG

  def post_list(posts:)
    htmg do
      ul(
        posts.map { |p| li(h(p.title), class: "post") }.join,
        class: "posts"
      )
    end
  end
end
```

### 4. Route (The Glue)

The route fetches data and passes it down:

```ruby
# app.rb
route do |r|
  r.root do
    # FETCH DATA HERE (only place)
    user = current_user
    posts = Repo::Posts.recent

    # PASS DATA DOWN
    HTMGHelpers.render_page(self, title: "Home") do
      Views.home(self, user: user, posts: posts)
    end
  end
end
```

---

## HTMX Pattern

Components are just functions. Call them directly for partials:

```ruby
# Full page
r.root do
  alerts = Repo::Alerts.recent

  HTMGHelpers.render_page(self, title: "Feed") do
    Components.alert_feed(alerts: alerts)
  end
end

# HTMX partial - just call component directly
r.get "partials/feed" do
  Components.alert_feed(alerts: Repo::Alerts.recent)
end
```

---

## Usage Summary

```ruby
# Views: ctx first, data as kwargs
Views.home(ctx, user: user, posts: posts)

# Components: data only (no ctx unless generating links)
Components.post_list(posts: posts)

# Layout: ctx, title, content via block
HTMGHelpers.render_page(ctx, title: "Home") do
  Views.home(ctx, user: user, posts: posts)
end
```

---

## Attribute Syntax

```ruby
# Standard attributes
a("Home", href: "/", class: "nav-link")

# Data/aria attributes (use quoted symbols for hyphens)
div("data-bs-toggle": "modal", "data-target": "#myModal")

# Boolean attributes
input(type: "checkbox", checked: true)
```

---

## Style Rules (MUST FOLLOW)

1. **Use ARGS style**: `div(h1("Title"), class: "card")` - children auto-joined
2. **Use `+` only when necessary**: Multiple top-level siblings that can't nest
3. **ctx is always first argument**: Every function takes `ctx` first
4. **Escape user content**: Always wrap dynamic content in `h()`
5. **Pre-compute before htmg**: Build data outside, render inside
6. **Use `content.call` for yield**: `main(content.call)` in layouts
7. **Asset helpers return raw strings**: No `htmg` wrapper for `<link>`/`<script>`
8. **Components are just functions**: Call them directly, no wrapper helpers needed

---

## Common Mistakes to Avoid

| Wrong | Correct |
|-------|---------|
| `div(user_input)` | `div(h(user_input))` |
| `@user.name` | Pass `user:` as argument |
| `scope.current_user` | Pass `ctx` and `user:` explicitly |
| `div("a") + div("b")` at top level | Nest: `div(div("a"), div("b"))` |
| Creating `render_partial` helper | Just call the component directly |

---

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| Missing elements | Block without `+` | Use ARGS style or add `+` |
| XSS vulnerability | Raw user input | Wrap in `h()` |
| NilClass error | Implicit state | Pass data as keyword argument |
| Attribute rendering wrong | Nested hash for data-* | Use `"data-key": "value"` |

---

## Examples

### Convert ERB to HTMG

ERB input:
```erb
<div class="card">
  <h2><%= @item.title %></h2>
  <p><%= @item.description %></p>
</div>
```

HTMG output:
```ruby
def card(ctx, item:)
  ctx.htmg do
    div(
      h2(h(item.title)),
      p(h(item.description)),
      class: "card"
    )
  end
end
```

### Create Navigation Component

Request: "Create a nav with login/logout based on user state"

```ruby
module Components
  extend self
  include HTMG

  def navbar(user:)
    htmg do
      nav(
        div("Logo", class: "brand"),
        div(
          if user
            span("Hello, #{h(user.name)}") +
            a("Logout", href: "/logout")
          else
            a("Login", href: "/login")
          end,
          class: "auth"
        ),
        class: "navbar"
      )
    end
  end
end
```

### Using Roda Path Helpers

Access route helpers via `ctx`:

```ruby
def toolbar(ctx, item:)
  ctx.htmg do
    nav(
      a("View Item", href: ctx.item_path(item)),
      a("Edit", href: ctx.edit_item_path(item)),
      class: "toolbar"
    )
  end
end
```

---

## Essential Helpers

| Helper | Purpose |
|--------|---------|
| `render_page(ctx, title:, &content)` | Full HTML document with layout |
| `css_*` / `js_*` | Asset includes (raw strings) |

That's it. Components are just functions—call them directly.
