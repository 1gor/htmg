# Changelog

## [Unreleased]

### Added
- Introduced the `HTMG` module for HTML generation using Ruby closures, replacing the previous imperative HTML generation logic.
- Added support for HTML5 tags by defining the `HTML5_TAGS` constant, ensuring compatibility with modern web standards.
- Implemented the `htmg` method to dynamically generate HTML using blocks (closures) for a more declarative approach to HTML generation.
- Introduced the `Generator` class to encapsulate the logic for generating HTML tags with attributes and nested content.
- Added the `method_missing` method in `Generator` to handle dynamic HTML tag generation.
- Provided an `extra_tags` mechanism to allow for custom HTML tags via an environment variable (`HTMG_EXTRA_TAGS`) or a constant (`HTMG::EXTRA_TAGS`).
- Implemented the `h` method to escape HTML entities, ensuring safe output for user-generated content.
- Added handling for self-closing tags, ensuring proper syntax for tags like `<img>`, `<br>`, etc.
- Introduced a mechanism to override Ruby's conflicting method names (e.g., `p`, `select`) to prevent method conflicts with HTML tags.
- Added `respond_to_missing?` to make the library compatible with Ruby's dynamic method dispatching.

### Changed
- Refactored the HTML generation from hard-coded string manipulation to a block-based (closure) system using `instance_eval`.
- Improved handling of attributes by introducing automatic escaping of attribute values (except for `class` and `id`).

### Removed
- Removed the hard-coded `print`-style HTML generation logic from the original source, transitioning to a dynamic tag-based approach.
