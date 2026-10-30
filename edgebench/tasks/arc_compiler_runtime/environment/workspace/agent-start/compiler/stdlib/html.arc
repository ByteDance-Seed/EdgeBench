# Arc Standard Library: html module
# HTML parsing and generation utilities

pub fn parse(s) {
  __native("html.parse", s)
}

pub fn select(node, selector) {
  __native("html.select", node, selector)
}

pub fn text(node) {
  __native("html.text", node)
}

pub fn attr(node, name) {
  __native("html.attr", node, name)
}

pub fn create(tag, attrs, children) {
  let node = {}
  node["tag"] = tag
  node["attrs"] = attrs
  node["children"] = children
  node
}

pub fn render(node) {
  __native("html.render", node)
}
