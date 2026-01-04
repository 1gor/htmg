# Passing Variables in HTMG

HTMG provides a structured way to pass and access variables in your views and components. This chapter explains how to effectively pass data through your application.

## Understanding the Scope

In HTMG, the `scope` is the current application instance (Sinatra/Roda app). This means:

- All helper methods are automatically available through `scope`
- Instance variables set in routes are accessible through `scope`
- The scope maintains the application's context

Example:
```ruby
# In route
get '/dashboard' do
  @stats = { visits: 1234, users: 56 }
  render_page(:dashboard)
end

# In view
def dashboard(context)
  context.htmg do |scope|
    div(class: "dashboard") do
      h2 { "Dashboard" }
      div(class: "stats") do
        p { "Visits: #{scope.stats[:visits]}" }
        p { "Users: #{scope.stats[:users]}" }
      end
    end
  end
end
```

## Using Helper Methods

For commonly used data, create helper methods:

```ruby
helpers do
  def current_user
    @current_user ||= User.find(session[:user_id])
  end

  def profile
    @profile ||= current_user.profile
  end
end
```

Then access them in views:
```ruby
def profile_view(context)
  context.htmg do |scope|
    div do
      h1 { scope.profile.name }
      p { scope.profile.bio }
    end
  end
end
```

## Passing Temporary Data

For route-specific data, use instance variables:

```ruby
get '/recent' do
  @recent_posts = Post.recent(5)
  render_page(:recent_posts)
end
```

Access in view:
```ruby
def recent_posts(context)
  context.htmg do |scope|
    div(class: "posts") do
      scope.recent_posts.each do |post|
        article do
          h2 { post.title }
          p { post.excerpt }
        end
      end
    end
  end
end
```

## Best Practices

1. **Use helpers for global/common data**
2. **Use instance variables for route-specific data**
3. **Keep data access explicit through scope**
4. **Avoid deep nesting in scope variables**
5. **Use meaningful names for variables and helpers**

## Comparison to ERB

| Feature          | ERB                     | HTMG                     |
|------------------|-------------------------|--------------------------|
| Global variables | `@variable`             | `scope.variable`         |
| Helpers          | `helper_method`         | `scope.helper_method`    |
| Locals           | `locals: { var: value }`| Instance variables       |
| Context          | Implicit                | Explicit through scope   |

## Example: Complete Flow

```ruby
# Route
get '/user/:id' do
  @user = User.find(params[:id])
  render_page(:user_profile)
end

# View
def user_profile(context)
  context.htmg do |scope|
    div(class: "profile") do
      h1 { scope.user.name }
      p { scope.user.bio }
      ul(class: "stats") do
        li { "Posts: #{scope.user.posts_count}" }
        li { "Followers: #{scope.user.followers_count}" }
      end
    end
  end
end
```

This approach provides a clean, maintainable way to pass data through your HTMG application while maintaining the benefits of structured templating.
