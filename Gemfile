# frozen_string_literal: true

source "https://rubygems.org"

# Mirrors what GitHub Pages builds this site with. Cayman now comes from the
# published gem rather than a vendored copy of the theme repo.
gem "jekyll", "~> 3.10"
gem "jekyll-theme-cayman", "~> 0.2"

# Jekyll defaults kramdown's input to GFM, and kramdown 2.x split that parser
# into its own gem. GitHub Pages' build bundles it implicitly; a plain
# `jekyll build` has to name it or every page fails to convert.
gem "kramdown-parser-gfm", "~> 1.1"

# Bundler's :jekyll_plugins group is auto-required by Jekyll, so these load in
# CI and locally without also needing to be listed under `plugins:`.
group :jekyll_plugins do
  gem "jekyll-seo-tag", "~> 2.8"
  gem "jemoji", "~> 0.13"
end

group :test do
  gem "html-proofer", "~> 3.19"
end
