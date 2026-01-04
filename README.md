# HTMG

**Functional HTML generation for Ruby.**

Stop string-mashing templates. Start composing functions.

HTMG treats HTML as data structures, not text files. It brings the power of **functional composition** to your Ruby views, allowing you to build stateless, testable, and reusable UI components without a templating language tax.

## Philosophy

Templates (ERB, Slim, Haml) separate your logic from your view structure. HTMG takes a different approach: **Your view is just a function.**

* **Code is Data:** HTML structure is defined by nesting Ruby function calls.
* **Composable:** A component is just a method that returns a tag.
* **Fast:** No parsing step. It runs at the speed of Ruby method calls.
* **Explicit:** Data is passed as arguments, not hidden in instance variables.

## Installation

```ruby
gem 'htmg'

```

## Usage

HTMG offers two ways to express HTML: **Argument Style** (functional) and **Block Style** (classic Ruby).

### 1. Argument Style (Recommended)

Pass content as arguments and attributes as keywords. This style avoids `end` soup and automatically joins siblings without manual concatenation.

**Convention:** Pass content first, then attributes (kwargs) last.

```ruby
def user_card(user)
  # Content args first, kwargs last
  div(
    h3(user.name),
    p(user.bio),
    a("Profile", href: "/u/#{user.id}"),
    class: "card" 
  )
end

```

### 2. Block Style

Use blocks when you need complex logic (like `if/else`) or prefer the visual nesting of `do...end`.

**Important:** Inside a block, you must explicitly join siblings using `+` or `.join`.

```ruby
div(id: "main") {
  # Use '+' to join siblings
  h1("Welcome") + 
  p("Please log in")
}

# OR use Array.join for lists
ul {
  items.map { |i| li(i.name) }.join
}

```

### The Entry Point (`htmg`)

The `htmg` method is the entry point. It **only accepts a block**.

If your top-level HTML has multiple root elements (e.g., a header and a footer), you must join them so the block returns a single string.

```ruby
# Single root element
puts htmg { div("Hello") }

# Multiple root elements (Must use + or .join)
puts htmg {
  header("Top") +
  main("Body") +
  footer("Bottom")
}

```

## Joining Elements: A Summary

Depending on your style, there are three ways to join sibling elements:

1. **Commas (Argument Style):** The cleanest way.
```ruby
div(h1("A"), p("B")) 

```


2. **Plus `+` (Block Style):** Explicit string concatenation.
```ruby
div { h1("A") + p("B") }

```


3. **Array `.join` (Collections):** Best for loops.
```ruby
ul(
  items.map { |i| li(i) }.join 
)

```



## Components & Composition

Because HTML tags are just functions, "Components" are just Ruby methods.

```ruby
module UI
  include HTMG

  def alert(title, message, variant: "info")
    div(
      h4(title, class: "font-bold"),
      p(message),
      class: "alert alert-#{variant}"
    )
  end
end

# Usage
htmg { 
  UI.alert("Success", "Record saved", variant: "success") 
}

```

## Attributes

Attributes are standard Ruby keyword arguments (`kwargs`).

* **Boolean:** `input(disabled: true)` renders `<input disabled />`.
* **Special Characters:** Quote the keys for weird attributes.
```ruby
button("@click": "open = true", "data-action": "save")

```


* **Safety:** Attributes are automatically escaped, **except** for `class` and `id` (to support complex Tailwind selectors like `[&>p]:text-red`).

## Security

* **Content:** Raw by default. We trust your Ruby code.
* **User Input:** Use the `h()` helper explicitly for untrusted input.

```ruby
div(h(user_input)) # Escaped
div(user_input)    # Raw

```

## Performance

HTMG is fast. It bypasses the template parsing phase entirely. In benchmarks, it matches the performance of **cached ERB** (production mode) and is ~2.5x faster than uncached ERB.

```
                 user     system      total        real
HTMG (Args):     0.570425   0.002896   0.573321 (  0.576280)
ERB (Cached):    0.557943   0.002945   0.560888 (  0.561023)
ERB (Uncached):  1.316579   0.000986   1.317565 (  1.317995)

```

## License

MIT

```

