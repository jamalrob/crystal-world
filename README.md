# The Crystal World

A blog application written in Crystal without a framework, inspired by the [Frameworkless Manifesto](https://github.com/frameworkless-movement/manifesto).

The main objectives here are:

- Implementing the basics without a framework:
  - routing
  - authentication and sessions
  - cookie management
  - template rendering
  - database access
  - CSRF and XSS prevention
- Testing different patterns and architectures
- Learning a new programming language that's as nice to read as Python or Ruby, and yet _fast_
- Building a groundwork for small real-world projects that's easy and enjoyable to use
- On the client-side, HTMX and Hyperscript has replaced all JavaScript to achieve a fast, SPA-like user experience

### Features

- Admin section/CMS:
- Edit articles in Markdown, with instant previews
- CRUD for articles, authors, pages, customization, and settings
- Choose from two separate modes of operation:
  - file-based (Markdown files with frontmatter)
  - or data-based (SQLite3 database)