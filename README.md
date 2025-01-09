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

```ruby

module LayoutHelper
  include HTMG

  # Define the layout as a method that accepts title, header, and content
  def layout(title:)
    htmg do |scope|
      html do
        [
          head { meta(title: title) },
          body {
            [
              header { scope.header_section },
              main { scope.content_section(title) }
              ].join
            }
        ].join
      end
    end
  end

  # Helper to define the header section
  def header_section
    htmg do
      ul(class: "nav") {
        [:foo, :bar].map { |n| li { "menu #{n}" } }.join
      }
    end
  end

  # Helper to define the content section
  def content_section(title)
    htmg do
      h1(class: "article-title") { title } +
      div(class: "text-black") { "Contents of the first article" }
    end
  end
end

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
