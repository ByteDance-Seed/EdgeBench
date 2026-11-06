# Async tasks (simulated)

fn fetch_data(url) => @GET url

let result = fetch_data("api/data")
print("Fetched: {result}")

# Simulated parallel work
let urls = ["api/a", "api/b", "api/c"]
for url in urls {
  let data = fetch_data(url)
  print("Got {url}: {data}")
}
