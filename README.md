# Tech Stack

- **Zig** (Language)
- **TypeScript/JavaScript** (Language)
- **Jetzig** (Web Framework), Backup: Zap (Web Framework)
    - Zmpl (Templating Language)
    - JetQuery (Database Layer)
        - PostgreSQL (Database; Compatible with JetQuery)
- **HTMX** (Front-end Framework)
- **Tailwind** (CSS Framework)
- **Motion** (Animation Library)
- **three.js** (WebGL Library)

## Why this stack?

`The goal is speed, efficiency, security, and most of all, simplicity. That is what I'm truly looking for.`

- **Zig** is a fast, safe, and relatively "simple" language (at least compared to other systems level languages without GC)
- **TypeScript/JavaScript** For use within the front-end
- **Jetzig** is currently the more fully featured web framework for Zig and offers a very alluring feature set offering:
    - **http.zig** as part of their backend
    - Templating with **Zmpl** (Their own templating language)
    - Built-in middleware for **HTMX**
    - Database layer through **JetQuery**
    - And more...
- **HTMX** is a fast, safe, and easy to learn front-end framework
    - To allow for fast and easy interactions between the front-end and back-end
    - To avoid javascript and big/bloated javascript frameworks (like React, Vue, etc...)
    - Has a large community with tons of examples/resources
- **Tailwind** is a fast, safe, and easy to learn CSS framework
    - Industry standard and has a large community with tons of examples/resources
- **Motion** A modern animation library
- **three.js** is a fast, safe, and easy to learn WebGL library for interesting and cool 3D effects

## Conventions

### Commits

Commit tag prefixes:
  - `Feat` - New feature
  - `Fix` - Bug fix
  - `Refactor` - Refactoring
  - `Perf` - Performance improvement
  - `Doc` - Documentation
  - `Test` - Test

Example: `Feat: Add new endpoint for adding new tasks`

```bash
git commit -m "Feat: Add new endpoint for adding new tasks"
```
### Branches

Branch names:
  - `dev` - Used for regular development
  - `main` - Used for production releases
  - `legacy` - Used for legacy versions of the website

### Routes

TODO:
