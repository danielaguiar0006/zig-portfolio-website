# zig-portfolio-website
run with: `zig build run`
runs on: localhost:9090

When changing things and want to be sure you are seeing the latest changes in your browser, make sure to **Hard Reload** the page.
To hard reload, press `Ctrl + F5` or `Shift + Reload Button` in chrome.

[inspiration](https://ysap.sh/)

---

## Ideas

- Global Dark, Light, and System modes
- Different fonts
- Custom Global theme colors
    - Make popular pre-made themes, but also allow users to create/import their own
        - Think about the safety implications
    - Make sure colors persist throughout the website for the user (maybe through cookies?)
- Make this whole project about showing off my skills and projects but also about creating somewhere to post my thoughts and ideas aswell as host my online projects
    - Projects such as mini-games, websites, "experiences", experiments, etc...
- Create a blog page with a list of post snippets
    - The blog page could just be an array of AsciiTables, each representing a post
    - Keep improving the AsciiTable library to make it more versatile and customizable
- HTMX?
- tailwindcss?
- DDOS protection?
- Cool generative/reactive background art like: [Keita Yamada Portfolio](https://p5aholic.me/)
    - Should i use three.js or another js library? or should I just use a canvas?
    - Would Raylib targeted for the web be a good choice?
        - Benchmark/compare Raylib web target vs three.js
        - Considering the fact that I want to host Raylib minigames on this/a website eventually this might be a good chance to try it out on the web
