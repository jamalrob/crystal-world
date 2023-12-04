# The Crystal World

A reinventing-the-wheel project, mainly for learning and consolidating my knowledge. It's a blog application written in the [Crystal](https://crystal-lang.org/) compiled programming language, with neither a front-end nor a back-end framework (inspired by the [Frameworkless Manifesto](https://github.com/frameworkless-movement/manifesto)).

And although it's _prima facie_ an old-fashioned server-centric dynamic website and thin-client CRUD application, in terms of UX it feels more like a Next.js or Astro SSG website, thanks to the judicious use of HTMX and Hyperscript.

The main objectives here are:

- Implementing the basics without a framework:
  - Routing
  - Authentication and sessions
  - Cookie management
  - Template rendering
  - Database access
  - CSRF and XSS prevention
  - Reactive UI, with no full page loads
- Testing different patterns and architectures
- Learning a new programming language that's as nice to read as Python or Ruby, but _fast_
- Building a usable groundwork for small real-world projects which is enjoyable to use
- On the client-side, replacing all (self-written) JavaScript with HTMX and Hyperscript while retaining a fast, SPA-like user experience

### Features

- Admin section/CMS
- Edit articles in Markdown, with instant previews
- CRUD for articles, authors, pages, customization, and settings
- Cloud API-based image management for CMS
- Choose from two separate modes of operation:
  - File-based (Markdown files with frontmatter)
  - Or data-based (SQLite3 database)

### Screenshots

![Home page](./screenshots/Screenshot-from-2023-12-01-14-50-03.png)

![Home page](./screenshots/Screenshot-from-2023-12-01-14-52-16.png)

![Home page](./screenshots/Screenshot-from-2023-12-01-14-33-56.png)

![Home page](./screenshots/Screenshot-from-2023-12-01-14-33-14.png)

![Home page](./screenshots/Screenshot-from-2023-12-01-14-35-40.png)

![Home page](./screenshots/Screenshot-from-2023-12-01-14-39-08.png)

![Home page](./screenshots/Screenshot-from-2023-12-01-14-39-19.png)

![Home page](./screenshots/Screenshot-from-2023-12-01-14-33-24.png)
