[![Tests](https://github.com/1gor/htmg/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/1gor/htmg/actions/workflows/main.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/f671fc97d3192e154cb5/maintainability)](https://codeclimate.com/github/1gor/htmg/maintainability)
[![Known Vulnerabilities](https://snyk.io/test/github/1gor/htmg/badge.svg)](https://snyk.io/test/github/1gor/htmg)

# HTMG - generate HTML with closures in Ruby

This library uses Ruby blocks (closures) to dynamically generate HTML, providing flexible DSL approach to building HTML documents. Its ability to work with custom helper methods (executed in a different scope) adds to its extensibility and modularity.

## Benchmark

HTMG is around 5x times faster than ERB. See `rspec/benchmark.rb`.

```
       user     system      total        real
HTMG with Data:  0.371457   0.000961   0.372418 (  0.372436)
ERB with Data:  1.874767   0.010206   1.884973 (  1.884978)
```

This speed advantage is due to HTMG functional, stateless approach, which directly generates HTML using Ruby blocks and method_missing without the need for template parsing or compilation.

## Why

There are plenty of alternative html builders. This one uses on speed and simplicity. It is about 100 lines of code. It makes html tags into closures (ruby blocks) that you can nest, combine and test easily. This library uses Ruby functional language features so no classes/objects, no state, no overhead and no uncertainty as to the outcome.

## Usage

### Using HTMG in a Sinatra Application

You can use the `htmg` gem in a Sinatra application by defining a layout and individual views. Here are some approaches:

#### Option 1: Define a Layout Method

Create a layout method that uses `htmg` to generate the common structure of your HTML pages. This method can be used to wrap individual view methods.

```ruby
# layout.rb
module LayoutHelper
  include HTMG

  def layout(title:, &block)
    html5 do
      head { title_tag { title } + stylesheet_link_tag("/styles.css") } +
      body { header { "My Site" } + main(&block) }
    end
  end
end
```

#### Option 2: Individual View Methods

Define individual methods for each view, using `htmg` to generate the specific content for each page.

```ruby
# views.rb
module Views
  include HTMG

  def home_view
    htmg do
      h1 { "Welcome to My Site" } +
      p { "This is the home page." }
    end
  end

  def about_view
    htmg do
      h1 { "About Us" } +
      p { "We are a company that does things." }
    end
  end
end
```

#### Option 3: Use in Sinatra Routes

Integrate the layout and view methods into your Sinatra routes.

```ruby
# app.rb
require 'sinatra'
require_relative 'layout'
require_relative 'views'

helpers LayoutHelper
helpers Views

get '/' do
  layout(title: "Home") { home_view }
end

get '/about' do
  layout(title: "About") { about_view }
end
```

These examples demonstrate how you can structure your Sinatra application to use the `htmg` gem for generating HTML content. You can define a common layout and individual views, then use them in your Sinatra routes to render complete pages.

### Basic Usage

```ruby
require 'htmg'

include HTMG

# Simple element
puts htmg { div { "Hello World" } }
# => <div>Hello World</div>

# With attributes
puts htmg { a(href: "https://example.com") { "Click me" } }
# => <a href="https://example.com">Click me</a>

# Nested elements
puts htmg { div(class: "container") { span { "Nested content" } } }
# => <div class="container"><span>Nested content</span></div>
```

### Layout Example

```ruby
module LayoutHelper
  include HTMG

  def full_page(title:)
    htmg do |scope|
      html5 do
        head { 
          meta(charset: "utf-8") +
          title_tag { title } 
        } +
        body {
          header { scope.navigation } +
          main { scope.content(title) } +
          footer { scope.footer_content }
        }
      end
    end
  end

  def navigation
    htmg do
      nav(class: "main-nav") {
        ul {
          %w[Home About Contact].map { |item| 
            li { a(href: "/#{item.downcase}") { item } }
          }.join
        }
      }
    end
  end

  def content(title)
    htmg do
      article {
        h1 { title } +
        section(class: "content") { "Main article content" }
      }
    end
  end

  def footer_content
    htmg do
      div(class: "footer") {
        "© #{Time.now.year} My Company"
      }
    end
  end
end
```

### Advanced Features

#### HTML5 Doctype
```ruby
puts htmg { html5 { body { "Content" } } }
# => <!DOCTYPE html><html><body>Content</body></html>
```

#### Common Helpers
```ruby
# Image tag helper
def img_tag(src, alt: "", **attrs)
  htmg { img(src: src, alt: alt, **attrs) }
end

# Form input helper
def input_field(type:, name:, **attrs)
  htmg { input(type: type, name: name, **attrs) }
end

# Table helper
def table(data, **attrs)
  htmg do
    table(**attrs) {
      thead {
        tr {
          data.first.keys.map { |header| th { header.to_s.capitalize } }.join
        }
      } +
      tbody {
        data.map { |row|
          tr {
            row.values.map { |value| td { value.to_s } }.join
          }
        }.join
      }
    }
  end
end
```

#### Custom Tags
```ruby
# Using environment variable
ENV['HTMG_EXTRA_TAGS'] = 'custom-tag,another-tag'

# Using constant
HTMG::EXTRA_TAGS = [:custom1, :custom2]

puts htmg { custom1 { "Custom content" } }
# => <custom1>Custom content</custom1>
```

#### Escaping Content
```ruby
# Unescaped content (default)
puts htmg { div { "<script>alert('hi')</script>" } }
# => <div><script>alert('hi')</script></div>

# Escaped content
puts htmg { div { h("<script>alert('hi')</script>") } }
# => <div>&lt;script&gt;alert(&#39;hi&#39;)&lt;/script&gt;</div>
```

When you call `htmg` method with a block, evrything inside this block is either a string or a method/function that returns a string. Therefore you should join them with a `+` sign or wrap them into an array and join, as shown above.

Inside the `htmg` block you can enter any standard html5 element and it will be treated as a function. If you need to use some non-standard tags you can add them to `HTMG::EXTRA_TAGS` constant or to the `HTMG_EXTRA_TAGS` environment variable, separated by comma.

Notice an optional `scope` block argument. It allows access the parent scope and call methods outside the `htmg` block.

Have a look at `spec` directory to see more examples.


## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/1gor/htmg.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
