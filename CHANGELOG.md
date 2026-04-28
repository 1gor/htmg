# Changelog

## [0.3.1] - 2026-04-28

### Removed
- `HTMG::SVG_TAGS` constant and built-in SVG tag dispatch. Adding SVG tags by default polluted the tag namespace with generic words (`text`, `use`, `pattern`, `mask`, `stop`, `marker`, `g`, `defs`, etc.) that users may legitimately have defined as helper methods on their context. With those tags in the default dispatch, calling such a method inside an `htmg` block silently rendered a tag instead of invoking the helper. Users who want to build SVG via HTMG calls can opt in by adding the relevant tags to `EXTRA_TAGS`. Icons are leaf data and are typically expressed more cleanly as raw SVG strings (helper methods returning `<svg>...</svg>`) than as nested tag-builder calls.

## [0.3.0] - 2026-04-28

### Fixed
- Empty non-void HTML elements (e.g. `<div>`, `<span>`, `<section>`) now render with an explicit closing tag — `<div></div>` rather than `<div />`. The previous self-closing form is invalid in HTML5: browsers parse `<div />` as an unclosed opening tag, causing subsequent siblings to nest inside it. This is a real-world bug that breaks layouts whenever an empty decorative element (like a separator) sits between siblings.

### Added
- `HTMG::HTML_VOID_ELEMENTS` constant listing the WHATWG HTML void elements (`area`, `base`, `br`, `col`, `embed`, `hr`, `img`, `input`, `link`, `meta`, `param`, `source`, `track`, `wbr`). Only these self-close when empty.
- `HTMG::SVG_TAGS` constant listing common SVG tags (`svg`, `path`, `circle`, `rect`, `line`, `polygon`, `polyline`, `ellipse`, `g`, `defs`, `use`, `text`, `tspan`, etc.). SVG is XML-namespaced and may legitimately self-close, so empty SVG elements continue to render as `<path />`.
- SVG tags are now recognised by default — no `EXTRA_TAGS` registration required for inline SVG icons.

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
