#!/usr/bin/env ruby
# frozen_string_literal: true

# Works out which URLs changed between the live site and a fresh build, for IndexNow.
#
# Usage: ruby tools/indexnow-diff.rb SITE_DIR SITE_URL PREVIOUS_MANIFEST
#
#   SITE_DIR           built site, e.g. _site
#   SITE_URL           e.g. https://dennisknodt.com
#   PREVIOUS_MANIFEST  URL (or local path) of the manifest currently live
#
# Writes SITE_DIR/indexnow-manifest.json (a fingerprint of every sitemap URL) so the
# next build can compare against it, and prints the added/changed/deleted URLs as a
# JSON array on stdout. With no previous manifest (first deploy) it prints [] so that
# existing pages are not submitted.
#
# A page's fingerprint covers only its <main> content, <title>, meta description and
# canonical link, so sidebar widgets ("Recently Updated", "Trending Tags") and
# build-time timestamps don't make every page look changed.

require "digest"
require "json"
require "net/http"
require "uri"

MANIFEST_NAME = "indexnow-manifest.json"

site_dir, site_url, previous_source = ARGV
abort "usage: #{$PROGRAM_NAME} SITE_DIR SITE_URL PREVIOUS_MANIFEST" unless previous_source
site_url = site_url.chomp("/")

def file_for(site_dir, site_url, loc)
  path = URI(loc).path.delete_prefix(URI(site_url).path)
  path += "index.html" if path.end_with?("/")
  File.join(site_dir, path)
end

def fingerprint(html)
  parts = [
    html[%r{<title>.*?</title>}m],
    html[/<meta name="description"[^>]*>/],
    html[/<link rel="canonical"[^>]*>/],
    html[%r{<main\b.*</main>}m] || html
  ]
  Digest::SHA256.hexdigest(parts.compact.join("\n"))
end

def load_previous(source)
  body =
    if source.start_with?("http")
      res = Net::HTTP.get_response(URI(source))
      unless res.is_a?(Net::HTTPSuccess)
        warn "IndexNow: no previous manifest (HTTP #{res.code}), saving a baseline"
        return nil
      end
      res.body
    else
      return nil unless File.exist?(source)
      File.read(source)
    end
  JSON.parse(body)
rescue StandardError => e
  warn "IndexNow: could not read previous manifest (#{e.class}: #{e.message}), saving a baseline"
  nil
end

sitemap = File.read(File.join(site_dir, "sitemap.xml"))
current = sitemap.scan(%r{<loc>\s*(.*?)\s*</loc>}).flatten.uniq.sort.to_h do |loc|
  file = file_for(site_dir, site_url, loc)
  [loc, File.exist?(file) ? fingerprint(File.read(file)) : nil]
end.compact

File.write(File.join(site_dir, MANIFEST_NAME), JSON.pretty_generate(current))

previous = load_previous(previous_source)
if previous.nil?
  puts "[]"
  exit
end

added = current.keys - previous.keys
deleted = previous.keys - current.keys
changed = current.keys.select { |url| previous.key?(url) && previous[url] != current[url] }

warn "IndexNow: #{added.size} added, #{changed.size} changed, #{deleted.size} deleted"
(added + changed + deleted).each { |url| warn "  #{url}" }
puts JSON.generate((added + changed + deleted).sort)
