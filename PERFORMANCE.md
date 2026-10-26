# Performance customizations

Page speed tweaks on top of the Chirpy theme. No theme files are overridden, so theme updates still apply.

| What | Where | Why | How to remove |
| --- | --- | --- | --- |
| Self-hosted fonts, icons and JS libraries | `assets.self_host.enabled: true` in `_config.yml`, `assets/lib` submodule, `submodules: true` and "Update self-hosted assets" step in `.github/workflows/pages-deploy.yml` | Avoids render-blocking requests to jsDelivr and Google Fonts | Set `enabled:` back to empty, remove the two workflow changes, `git rm assets/lib` (and the `.gitmodules` entry) |
| Font subsetting | `tools/subset-fonts.sh`, "Subset self-hosted fonts" workflow step | Self-hosted text fonts include every script; this cuts them to Latin/Vietnamese like Google Fonts (~45% smaller) | Delete the script and the workflow step |
| Lato Light | `assets/fonts/lato/`, injected by `_plugins/performance-hooks.rb` | The self-hosted fonts lack Lato 300, used for post descriptions | Delete the folder and the `lato_light_css` part of the plugin (not needed if self-hosting is removed) |
| Non-blocking icon CSS | `_plugins/performance-hooks.rb` (`non_blocking_css`) | Font Awesome CSS no longer delays the first paint; icons stay hidden until their font loads either way | Remove that part of the plugin |
| Eager first home preview | `_plugins/performance-hooks.rb` (home layout block) | It is the LCP element on mobile; also clears its own loading shimmer, since the theme only does that for lazy images | Remove that part of the plugin |
| Optimized images | `assets/img/` | Avatar resized to 448 px; PNG photos converted to JPEG; favicon.svg re-embedded at its 566 px size | Nothing to remove; the originals are in git history (before commit 7059823) |

The plugin only rewrites generated HTML and does nothing if the theme markup changes. To check its effect, build the site and look for `fetchpriority="high"` and `media="print"` in `_site/index.html`.
