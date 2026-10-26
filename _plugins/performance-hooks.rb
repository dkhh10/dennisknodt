#!/usr/bin/env ruby
#
# Page speed tweaks applied to the rendered HTML, so no theme files are overridden.
# If the theme markup changes, the patterns stop matching and nothing is replaced.

# Load the icon and lazy-load polyfill stylesheets without blocking the first paint.
# Icons use `font-display: block`, so they stay hidden until their font arrives either way.
NON_BLOCKING_CSS = %r{<link rel="stylesheet" href="([^"]*(?:fontawesome-free/css/all\.min\.css|loading-attribute-polyfill\.min\.css))">}

def non_blocking_css(html)
  html.gsub(NON_BLOCKING_CSS) do
    %(<link rel="stylesheet" href="#{$1}" media="print" onload="this.media='all'">) +
      %(<noscript><link rel="stylesheet" href="#{$1}"></noscript>)
  end
end

# The self-hosted theme fonts lack Lato Light (300), which the theme uses for post
# descriptions. Add it with the same files and character ranges Google Fonts serves.
SELF_HOSTED_FONTS_CSS = %r{<link rel="stylesheet" href="[^"]*/assets/lib/fonts/main\.css">}

def lato_light_css(baseurl)
  dir = "#{baseurl}/assets/fonts/lato"
  face = "@font-face{font-family:Lato;font-style:normal;font-weight:300;font-display:swap;"
  "<style>" \
    "#{face}src:url(#{dir}/Lato-Light-latin-ext.woff2) format('woff2');" \
    "unicode-range:U+0100-02BA,U+02BD-02C5,U+02C7-02CC,U+02CE-02D7,U+02DD-02FF,U+0304,U+0308," \
    "U+0329,U+1D00-1DBF,U+1E00-1E9F,U+1EF2-1EFF,U+2020,U+20A0-20AB,U+20AD-20C4,U+2113,U+2C60-2C7F,U+A720-A7FF}" \
    "#{face}src:url(#{dir}/Lato-Light-latin.woff2) format('woff2');" \
    "unicode-range:U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308," \
    "U+0329,U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD}" \
  "</style>"
end

Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|

  next unless doc.output_ext == '.html'

  doc.output = non_blocking_css(doc.output)
  doc.output = doc.output.sub(SELF_HOSTED_FONTS_CSS) { "#{$&}#{lato_light_css(doc.site.baseurl)}" }

  # The first post preview on the home page is the largest element above the fold
  # (LCP), so load it eagerly with high priority instead of lazily. The theme only
  # clears the loading shimmer of lazy images that finish before its script runs,
  # so the image clears its own shimmer on load.
  if doc.data['layout'] == 'home'
    doc.output = doc.output.sub(
      /(<div class="preview-img[^"]*"><img [^>]*?)\s*loading="lazy"/,
      %q(\1 fetchpriority="high" onload="this.parentElement.classList.remove('shimmer')")
    )
  end

end
