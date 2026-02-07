# HTMG

**Functional HTML generation for Ruby.**

HTMG treats HTML as data structures, not text files. It brings the power of **functional composition** to your Ruby views, allowing you to build stateless, testable, and reusable UI components without a templating language tax.

## Philosophy: The "MatzLisp" Way

Templates (ERB, Slim) separate logic from structure, often leading to "magic" context and implicit dependencies. HTMG takes a different approach: **Your view is just a function.**

* **Code is Data:** HTML structure is defined by nesting Ruby function calls.
* **Unidirectional Data Flow:** Data is passed explicitly down from the route to the view. Views never "pull" data.
* **Explicit over Implicit:** No magical `scope` or `instance_variables`. If a view needs data, it must be passed as an argument.
* **Boring Technology:** Just Ruby. No parsers, no distinct compilation step.

## Installation

```ruby
gem 'htmg'

```

## Architectural Guide

HTMG is designed to be used with a **Functional View Pattern**. This works exceptionally well with Roda, Sinatra, and Hanami.

### 1. The Route is the Composer

The route (Controller) is responsible for fetching data and coordinating the view. It passes the application context (`self`) and data explicitly.

```ruby
# app.rb (Roda Example)
route do |r|
  r.root do
    # 1. Fetch Data
    user = current_user
    posts = Repo::Posts.recent

    # 2. Render Page (Pure Function)
    content = Views::Home.call(self, user: user, posts: posts)

    # 3. Wrap in Layout (Wrapper Function)
    Views::Layout.application(self, title: "Home", user: user) do
      content
    end
  end
end

```

### 2. Views are Pure Functions

Views should be modules with stateless methods. They accept:

1. `ctx`: The app context (for helpers like `csrf_tag`, `routes`).
2. `**data`: Explicit keyword arguments for all required data.

```ruby
# views/home.rb
module Views
  extend self

  def home(ctx, user:, posts:)
    ctx.htmg do
      div(class: "container") {
        h1 { "Welcome, #{h(user.name)}" } +
        # Component Composition
        Components.post_list(posts: posts)
      }
    end
  end
end

```

### 3. Components are Dumb

Components should not know about the `ctx` (unless they generate links) and definitely should not know about the database. They just render what they are given.

```ruby
# views/components.rb
module Views
  module Components
    extend self

    def post_list(posts:)
      htmg do
        ul(class: "posts") {
          posts.map { |post| 
            li { h(post.title) } 
          }.join
        }
      end
    end
  end
end

```

### 4. Layouts are Wrappers

A layout is simply a function that takes a block and `yield`s the content into place.

```ruby
# views/layout.rb
module Views
  module Layout
    extend self

    def application(ctx, title:, user:)
      "<!DOCTYPE html>" + ctx.htmg do
        html do
          head { title { h(title) } } +
          body do
            header { "User: #{h(user.name)}" } +
            main { yield } + # Inject content here
            footer { "© 2024" }
          end
        end
      end
    end
  end
end

```

## Usage Syntax

HTMG offers two ways to express HTML.

### Argument Style (Recommended for Leaves)

Pass content as arguments. Cleaner for simple elements.

```ruby
# <div class="card"><h1>Title</h1></div>
div(h1("Title"), class: "card")

```

### Block Style (Recommended for Structure)

Use blocks for nesting. **Crucial:** You must explicitly join siblings.

```ruby
# <main><h1>Title</h1><p>Text</p></main>
main {
  h1 { "Title" } +   # Use + to join siblings
  p { "Text" }
}

```

### Collections

Use standard Ruby `.map` and `.join`.

```ruby
ul {
  items.map { |i| li { i.name } }.join
}

```

### Safety & Escaping

* **Attributes:** Auto-escaped (except `class`/`id` for Tailwind safety).
* **Content:** Raw by default. **YOU** must escape user input.

```ruby
div(user_content)      # Renders HTML (Unsafe)
div(h(user_content))   # Escaped (Safe)

```

## Best Practices (Dos and Don'ts)

| Category | Do | Don't |
| --- | --- | --- |
| **State** | Pass data as explicit arguments (`user: user`). | Do not rely on `scope.current_user` or instance vars (`@user`). |
| **Logic** | Keep logic in the Route/Repository. | Do not fetch data inside a View or Component. |
| **Context** | Pass `ctx` (self) for helpers/routes. | Do not use global helpers or mixins. |
| **HTMX** | Reuse components for partial responses. | Do not duplicate logic for AJAX/Socket updates. |
| **Safety** | Explicitly use `h()` for dynamic content. | Do not interpolate strings blindly. |

## HTMX / Reactive Pattern

HTMG shines with "HTML over the Wire" (HTMX, Hotwire). Because components are just functions, you can reuse them for both full-page renders and partial updates.

**Route:**

```ruby
r.on "partials" do
  r.get "feed" do
    # Reuse the SAME component used in the main layout
    alerts = Repo::Alerts.recent
    Views::Components.alert_feed(alerts: alerts)
  end
end

```

**Component:**

```ruby
def alert_feed(alerts:)
  htmg do
    div(id: "feed") { 
      alerts.map { |a| div(class: "alert") { a.msg } }.join 
    }
  end
end

```

## Performance

HTMG bypasses template parsing and string scanning, running at the speed of Ruby method calls. It is generally comparable to cached ERB and significantly faster than uncached templates.

## License

MIT
