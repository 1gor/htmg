# HTMG (HTML Template MetaGem) Context Reference

## Core Concepts
- HTML generation via nested Ruby blocks
- Tags methods: `tag_name(attributes) { content }`
- Automatic closing: Content block? full tag : self-closing
- Attribute escaping: Automatic except class/id
- Content escaping: Manual via `h()` method

## Basic Syntax Examples
```ruby
# Simple element
div { "content" } → "<div>content</div>"

# With attributes
a(href: "/") { "Home" } → '<a href="/">Home</a>'

# Nested elements
ul {
  li { "Item 1" } +
  li(class: "active") { "Item 2" }
}
→ "<ul><li>Item 1</li><li class=\"active\">Item 2</li></ul>"
```

## Security Practices
```ruby
# UNSAFE (no escaping)
div { user_input }

# SAFE (explicit escaping)
div { h(user_input) }

# Attributes auto-escaped EXCEPT class/id:
input(value: "a&b") → <input value="a&amp;b" />
div(class: "a&b") → <div class="a&b"></div>
```

## Special Cases
```ruby
# Void elements (no content)
br → "<br />"

# Data attributes
div("data-id": "123") → <div data-id="123"></div>

# Conflicting Ruby methods
p { "text" } → "<p>text</p>" # Overrides Kernel#p
```

## Advanced Patterns
```ruby
# Component building
def card(title, content)
  div(class: "card") {
    h3 { title } +
    div(class: "content") { content }
  }
end

# String concatenation
html {
  head { ... } +
  body { ... }
}
```

## Common Errors
- Missing `h()` on user content → XSS risk
- Using blocks with void elements → Invalid HTML
- Ruby keyword collisions (class/method) → Use tag methods
- String interpolation without escaping → Use `h()`
