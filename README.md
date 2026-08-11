# ViLMa — Visual Localization and Mapping Workshop

Source for [vilma-workshop.github.io](https://vilma-workshop.github.io), the site for the
ViLMa workshop series. Built with Jekyll on GitHub Pages using the
[Cayman](https://github.com/pages-themes/cayman) theme.

## Layout

```
index.md                       current edition (ViLMa @ ECCV 2026)
cvpr2024/index.md              archived edition, served at /cvpr2024/
_data/editions.yml             every edition; drives the header switcher
_includes/edition-switcher.html
_layouts/default.html          Cayman's layout plus the nav and switcher
assets/css/style.scss          brand colours and custom components
assets/imgs/, assets/slides/   photos, conference logos, talk slides
```

## Editing a page

Each page's front matter drives the header:

```yaml
title: ViLMa @ ECCV 2026     # shown as the tagline, and in <title>
description: ...             # meta description for search results
edition: eccv2026            # must match an id in _data/editions.yml
nav:                         # the buttons in the header
  - title: Topic
    anchor: topic            # links to `## Topic {#topic}` in the body
```

Asset paths must be absolute (`/assets/...`) so they resolve from
subdirectories as well as the root.

## Adding a new edition

1. Add an entry to the top of `_data/editions.yml` with `current: true`, and
   drop `current` from the previous one.
2. Copy the current `index.md` to `<edition-id>/index.md` to archive it, add the
   archive notice at the top, and set its `edition:` to match.
3. Write the new `index.md` for the upcoming edition.

The header switcher and the footer pick the new edition up automatically.

## Running locally

Needs Ruby 3.x — macOS system Ruby (2.6) is too old for the current gems.

```sh
script/bootstrap    # bundle install
script/server       # serve at http://127.0.0.1:4000
script/cibuild      # build + internal link check, same as CI
```
