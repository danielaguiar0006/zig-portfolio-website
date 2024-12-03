# Tech Stack

- **Zig** (Language)
- **Jetzig** (Web Framework), Backup: Zap (Web Framework)
- **Tailwind** (CSS Framework)
- **HTMX** (Frontend Framework)

## Why this stack?

`The goal is speed, efficiency, security, and most of all, simplicity is what I'm truly looking for.`

- **Zig** is a fast, safe, and relatively "simple" language alteast compared to other systems level languages.
- **Jetzig** is currently the more fully featured web framework for Zig and offers a very alluring feature set offering:
    - **http.zig** as part of their backend
    - Templating with **Zmpl** (Their own templating language)
    - Built-in middleware for **HTMX**
    - Database layer through **JetQuery**
    - And more...
- **Tailwind** is a fast, safe, and easy to learn CSS framework
    - Industry standard and has a large community with tons of examples/resources
- **HTMX** is a fast, safe, and easy to learn frontend framework
    - To allow for fast and easy interactions between the frontend and backend
    - To avoid javascript and big/bloated javascript frameworks (like React, Vue, etc...)
    - Has a large community with tons of examples/resources

## How?

- Go through a major refactor period and replace all of the zap code with Jetzig
- Don't go through the original plan of generating all of the html through code, instead aim to create a powerful intersting website
