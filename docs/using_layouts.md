# Using Layouts in HTMG

HTMG provides a flexible layout system that allows you to create reusable page structures. This chapter explains how to create and use different layouts in your application.

## Basic Layout Structure

A layout is a view component that wraps your page content. Here's the basic structure:

```ruby
module Views
  module Layouts
    include HTMG
    extend self

    def application(context:, title:, &content)
      "<!DOCTYPE html>" + context.htmg do |scope|
        html do
          head {
            meta(charset: "utf-8") +
            title { "#{title} | My App" }
          } +
          body { content.call }
        end
      end
    end
  end
end
```

## Using Layouts

To use a layout, pass it to the `render_page` method:

```ruby
def render_page(name, layout: :application)
  content = -> { Views::Pages.public_send(name, self) }
  Views::Layouts.public_send(
    layout,
    context: self,
    title: "Page Title"
  ) { content.call }
end
```

## Creating Multiple Layouts

You can create multiple layouts for different purposes:

```ruby
module Views
  module Layouts
    include HTMG
    extend self

    # Default application layout
    def application(context:, title:, &content)
      "<!DOCTYPE html>" + context.htmg do |scope|
        html do
          head {
            meta(charset: "utf-8") +
            title { "#{title} | My App" } +
            style { "/* default styles */" }
          } +
          body {
            Components.navigation(scope) +
            main { content.call } +
            Components.footer(scope)
          }
        end
      end
    end

    # Minimal layout
    def minimal(context:, title:, &content)
      "<!DOCTYPE html>" + context.htmg do |scope|
        html do
          head {
            meta(charset: "utf-8") +
            title { title }
          } +
          body { content.call }
        end
      end
    end

    # Admin layout
    def admin(context:, title:, &content)
      "<!DOCTYPE html>" + context.htmg do |scope|
        html do
          head {
            meta(charset: "utf-8") +
            title { "#{title} | Admin" } +
            style { "/* admin styles */" }
          } +
          body(class: "admin") {
            Components.admin_navigation(scope) +
            main { content.call }
          }
        end
      end
    end
  end
end
```

## Using Different Layouts

You can specify which layout to use when rendering a page:

```ruby
# Using default layout
get '/' do
  render_page(:home)
end

# Using minimal layout
get '/minimal' do
  render_page(:home, layout: :minimal)
end

# Using admin layout
get '/admin' do
  render_page(:dashboard, layout: :admin)
end
```

## Layout Best Practices

1. **Keep layouts focused**: Each layout should serve a specific purpose
2. **Use meaningful names**: Name layouts after their purpose (e.g., :admin, :public, :minimal)
3. **Share common components**: Use shared components for navigation, headers, and footers
4. **Keep layout logic simple**: Move complex logic to helpers or components
5. **Use CSS classes for layout-specific styling**

## Example: Complete Layout Flow

```ruby
# Route
get '/profile' do
  render_page(:profile, layout: :user)
end

# Layout
def user(context:, title:, &content)
  "<!DOCTYPE html>" + context.htmg do |scope|
    html do
      head {
        meta(charset: "utf-8") +
        title { "#{title} | User Area" } +
        style { "/* user-specific styles */" }
      } +
      body(class: "user") {
        Components.user_navigation(scope) +
        main { content.call } +
        Components.user_footer(scope)
      }
    end
  end
end

# View
def profile(context)
  context.htmg do |scope|
    div(class: "profile") do
      h1 { scope.user.name }
      p { scope.user.bio }
    end
  end
end
```

This approach provides a flexible and maintainable way to manage different page layouts in your HTMG application.
