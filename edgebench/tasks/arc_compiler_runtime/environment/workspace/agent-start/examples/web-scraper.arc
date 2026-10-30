# Web Scraper (Mock)
# Demonstrates: tool calls, pipelines, string operations, maps

# Fetch mock pages
let page = @GET "api/page/example.com"
print("Fetched page: {page}")

# Extract links (simulated)
fn extract_links(html) {
  # In a real scraper, we'd parse HTML
  # Here we simulate with mock data
  let links = [
    {url: "https://example.com/about", text: "About Us"},
    {url: "https://example.com/products", text: "Products"},
    {url: "https://example.com/blog", text: "Blog"},
    {url: "https://example.com/contact", text: "Contact"}
  ]
  links
}

fn extract_text(html) {
  # Simulated text extraction
  "Welcome to Example Corp. We build amazing products."
}

fn crawl(url, depth) {
  if depth <= 0 { ret [] }
  print("Crawling: {url} (depth={depth})")
  let page = @GET url
  let links = extract_links(page)
  let texts = extract_text(page)

  let mut results = [{url: url, text: texts, link_count: len(links)}]

  for link in links |> take(2) {
    let sub = crawl(link.url, depth - 1)
    for r in sub {
      results = push(results, r)
    }
  }
  results
}

# Demo
print("=== Web Scraper ===")
let results = crawl("https://example.com", 1)

print("\nCrawl results:")
for r in results {
  print("  {r.url}: {r.link_count} links")
  print("    Text: {slice(r.text, 0, 50)}...")
}

print("\nTotal pages crawled: {len(results)}")
