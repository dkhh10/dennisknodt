#!/usr/bin/env ruby
#
# Keep the per-tag and per-category pages out of search results. Each one only lists
# a few posts, so they are thin pages that compete with the posts themselves.
# Visitors can still use them, and crawlers still follow their links to the posts.

def archive_page?(page)
  defined?(Jekyll::Archives::Archive) && page.is_a?(Jekyll::Archives::Archive)
end

# Runs after jekyll-archives creates the pages (normal priority)
# and before jekyll-sitemap writes the sitemap (lowest priority).
class ArchivePagesOutOfSitemap < Jekyll::Generator
  safe true
  priority :low

  def generate(site)
    site.pages.each { |page| page.data['sitemap'] = false if archive_page?(page) }
  end
end

Jekyll::Hooks.register :pages, :post_render do |page|
  next unless archive_page?(page)

  page.output = page.output.sub('<head>', '<head><meta name="robots" content="noindex, follow">')
end
