# ============================================================================
# Virtual Filesystem in Arc
# ============================================================================
# A complete in-memory virtual filesystem with tree-structured directories,
# file CRUD, path resolution, search, and disk usage stats.
# Demonstrates: pattern matching, recursion, closures, pipelines, regex,
# collections, string interpolation, mut, pub.
# ============================================================================

use regex: find
use collections

# --- Node Types ---

let NODE_FILE = "file"
let NODE_DIR  = "directory"
let NODE_LINK = "symlink"

# --- Permission Helpers ---

pub fn permission_string(perms) {
    let owner = format_rwx(perms.owner or 7)
    let group = format_rwx(perms.group or 5)
    let other = format_rwx(perms.other or 5)
    "{owner}{group}{other}"
}

fn format_rwx(bits) {
    let r = if bits >= 4 { "r" } el { "-" }
    let w = if (bits % 4) >= 2 { "w" } el { "-" }
    let x = if (bits % 2) >= 1 { "x" } el { "-" }
    "{r}{w}{x}"
}

# --- Node Creation ---

pub fn create_file(name, content, owner) => {
    kind: NODE_FILE,
    name: name,
    content: content or "",
    size: len(content or ""),
    owner: owner or "root",
    group: owner or "root",
    permissions: {owner: 6, group: 4, other: 4},
    created_at: "now",
    modified_at: "now"
}

pub fn create_dir(name, owner) => {
    kind: NODE_DIR,
    name: name,
    children: {},
    owner: owner or "root",
    group: owner or "root",
    permissions: {owner: 7, group: 5, other: 5},
    created_at: "now",
    modified_at: "now"
}

pub fn create_symlink(name, target, owner) => {
    kind: NODE_LINK,
    name: name,
    target: target,
    owner: owner or "root",
    group: owner or "root",
    permissions: {owner: 7, group: 7, other: 7},
    created_at: "now"
}

# --- Filesystem ---

pub fn create_fs() => {
    root: create_dir("/", "root"),
    cwd: "/"
}

# --- Path Utilities ---

fn normalize_path(path) {
    let parts = path |> split("/") |> filter(p => p != "")
    let resolved = fold(parts, [], (stack, part) => {
        match part {
            "." => stack,
            ".." => {
                if len(stack) > 0 { take(stack, len(stack) - 1) } el { stack }
            },
            _ => push(stack, part)
        }
    })
    "/" ++ join(resolved, "/")
}

fn resolve_path(fs, path) {
    if starts(path, "/") { normalize_path(path) }
    el { normalize_path("{fs.cwd}/{path}") }
}

fn path_parts(path) {
    path |> split("/") |> filter(p => p != "")
}

fn parent_path(path) {
    let parts = path_parts(path)
    if len(parts) <= 1 { "/" }
    el { "/" ++ join(take(parts, len(parts) - 1), "/") }
}

fn basename(path) {
    let parts = path_parts(path)
    if len(parts) == 0 { "/" } el { last(parts) }
}

# --- Navigation ---

fn get_node(fs, path) {
    let full_path = resolve_path(fs, path)
    let parts = path_parts(full_path)

    fold(parts, fs.root, (node, part) => {
        if node == nil { nil }
        el if node.kind == NODE_DIR {
            let ch = node.children
            ch[part]
        }
        el if node.kind == NODE_LINK { get_node(fs, node.target) }
        el { nil }
    })
}

fn set_node(fs, path, new_node) {
    let full_path = resolve_path(fs, path)
    let parts = path_parts(full_path)

    if len(parts) == 0 {
        let mut f = fs
        f.root = new_node
        f
    } el {
        let parent = parent_path(full_path)
        let name = basename(full_path)
        let parent_node = get_node(fs, parent)

        if parent_node == nil { fs }
        el if parent_node.kind == NODE_DIR {
            let mut p = parent_node
            p.children[name] = new_node
            p.modified_at = "now"
            set_node(fs, parent, p)
        }
        el { fs }
    }
}

# --- File Operations ---

pub fn mkdir(fs, path, owner) {
    let full_path = resolve_path(fs, path)
    let name = basename(full_path)
    let existing = get_node(fs, full_path)

    if existing == nil {
        let dir = create_dir(name, owner)
        set_node(fs, full_path, dir)
    } el {
        print("mkdir: '{full_path}' already exists")
        fs
    }
}

pub fn mkdir_p(fs, path, owner) {
    let parts = path_parts(resolve_path(fs, path))
    let mut current_fs = fs
    let mut current_path = ""

    for part in parts {
        current_path = "{current_path}/{part}"
        let node = get_node(current_fs, current_path)
        if node == nil {
            current_fs = mkdir(current_fs, current_path, owner)
        }
    }

    current_fs
}

pub fn touch(fs, path, content, owner) {
    let full_path = resolve_path(fs, path)
    let name = basename(full_path)
    let existing = get_node(fs, full_path)
    if existing == nil {
        let file = create_file(name, content or "", owner)
        set_node(fs, full_path, file)
    } el if existing.kind == NODE_FILE {
        let mut f = existing
        f.modified_at = "now"
        if content != nil {
            f.content = content
            f.size = len(content)
        }
        set_node(fs, full_path, f)
    } el {
        print("touch: '{full_path}' is not a file")
        fs
    }
}

pub fn write_file(fs, path, content, owner) {
    touch(fs, path, content, owner)
}

pub fn read_file(fs, path) {
    let node = get_node(fs, resolve_path(fs, path))
    if node == nil { {error: "File not found: {path}"} }
    el if node.kind == NODE_FILE { {ok: node.content} }
    el if node.kind == NODE_LINK { read_file(fs, node.target) }
    el { {error: "Not a file: {path}"} }
}

pub fn append_file(fs, path, content) {
    let node = get_node(fs, resolve_path(fs, path))
    if node != nil and node.kind == NODE_FILE {
        let new_content = node.content ++ content
        let mut f = node
        f.content = new_content
        f.size = len(new_content)
        f.modified_at = "now"
        set_node(fs, resolve_path(fs, path), f)
    } el {
        print("append: not a file")
        fs
    }
}

pub fn rm(fs, path) {
    let full_path = resolve_path(fs, path)
    let par = parent_path(full_path)
    let name = basename(full_path)
    let parent_node = get_node(fs, par)

    if parent_node != nil and parent_node.kind == NODE_DIR {
        let mut p = parent_node
        # Remove child by rebuilding children without the key
        let child_keys = keys(p.children) |> filter(k => k != name)
        let mut new_children = {}
        for k in child_keys {
            new_children[k] = p.children[k]
        }
        p.children = new_children
        p.modified_at = "now"
        set_node(fs, par, p)
    } el {
        fs
    }
}

pub fn cp(fs, src, dst, owner) {
    let node = get_node(fs, resolve_path(fs, src))
    if node == nil {
        print("cp: '{src}' not found")
        fs
    } el if node.kind == NODE_FILE {
        let mut f = node
        f.name = basename(resolve_path(fs, dst))
        set_node(fs, resolve_path(fs, dst), f)
    } el {
        print("cp: directories not yet supported")
        fs
    }
}

pub fn ln_s(fs, target, link_path, owner) {
    let full_path = resolve_path(fs, link_path)
    let name = basename(full_path)
    let link = create_symlink(name, target, owner)
    set_node(fs, full_path, link)
}

# --- Directory Listing ---

pub fn ls(fs, path) {
    let target = path or fs.cwd
    let node = get_node(fs, resolve_path(fs, target))
    if node == nil { {error: "Not found: {target}"} }
    el if node.kind == NODE_DIR {
        let ch = node.children
        keys(ch) |> sort |> map(k => {
            let n = ch[k]
            {
                name: k,
                kind: n.kind,
                size: if n.kind == NODE_FILE { n.size } el { 0 },
                permissions: permission_string(n.permissions),
                owner: n.owner,
                modified: n.modified_at or n.created_at
            }
        })
    }
    el { {error: "Not a directory: {target}"} }
}

pub fn ls_la(fs, path) {
    let listing = ls(fs, path)
    if type_of(listing) == "map" and listing.error != nil {
        print("ls: {listing.error}")
    } el {
        print("total {len(listing)}")
        for e in listing {
            let type_char = match e.kind {
                "directory" => "d",
                "symlink" => "l",
                _ => "-"
            }
            print("{type_char}{e.permissions} {e.owner}    {e.size} {e.name}")
        }
    }
}

# --- Search ---

pub fn find_files(fs, path, predicate) {
    let start = get_node(fs, resolve_path(fs, path))
    let base_path = resolve_path(fs, path)

    fn search(node, current_path) {
        if node == nil { ret [] }
        if node.kind == NODE_DIR {
            let self_result = if predicate(node, current_path) { [current_path] } el { [] }
            let child_keys = keys(node.children)
            let child_results = child_keys |> map(k => {
                let child_path = if current_path == "/" { "/{k}" } el { "{current_path}/{k}" }
                search(node.children[k], child_path)
            }) |> flat
            self_result ++ child_results
        } el {
            if predicate(node, current_path) { [current_path] } el { [] }
        }
    }

    search(start, base_path)
}

pub fn find_by_name(fs, path, pattern) {
    find_files(fs, path, (node, p) => regex.test(pattern, node.name))
}

pub fn find_by_kind(fs, path, kind) {
    find_files(fs, path, (node, p) => node.kind == kind)
}

pub fn grep(fs, path, pattern) {
    let files = find_by_kind(fs, path, NODE_FILE)
    files |> map(file_path => {
        let result = read_file(fs, file_path)
        if result.ok != nil {
            let lines = result.ok |> split("\n")
            let mut matches = []
            for i in 0..len(lines) {
                if regex.test(pattern, lines[i]) {
                    matches = push(matches, {file: file_path, line: i + 1, text: lines[i]})
                }
            }
            matches
        } el { [] }
    }) |> flat
}

# --- Disk Usage ---

fn calculate_size(node) {
    if node == nil { 0 }
    el if node.kind == NODE_FILE { node.size }
    el if node.kind == NODE_DIR {
        let child_keys = keys(node.children)
        fold(child_keys, 0, (total, k) => total + calculate_size(node.children[k]))
    }
    el { 0 }
}

pub fn du(fs, path) {
    let node = get_node(fs, resolve_path(fs, path))
    calculate_size(node)
}

pub fn tree(fs, path, prefix) {
    let node = get_node(fs, resolve_path(fs, path))
    let p = prefix or ""

    if node != nil and node.kind == NODE_DIR {
        let child_keys = keys(node.children) |> sort
        for i in 0..len(child_keys) {
            let key = child_keys[i]
            let child = node.children[key]
            let is_last = i == len(child_keys) - 1
            let connector = if is_last { "L-- " } el { "|-- " }
            let child_prefix = if is_last { "{p}    " } el { "{p}|   " }

            let type_indicator = match child.kind {
                "directory" => "/",
                "symlink" => " -> {child.target}",
                _ => " ({child.size}b)"
            }

            print("{p}{connector}{key}{type_indicator}")

            if child.kind == NODE_DIR {
                tree(fs, "{resolve_path(fs, path)}/{key}", child_prefix)
            }
        }
    }
}

# --- Change Directory ---

pub fn cd(fs, path) {
    let full_path = resolve_path(fs, path)
    let node = get_node(fs, full_path)
    if node == nil { print("cd: '{path}' not found"); fs }
    el if node.kind == NODE_DIR { let mut f = fs; f.cwd = full_path; f }
    el { print("cd: '{path}' is not a directory"); fs }
}

pub fn pwd(fs) => fs.cwd

# --- Filesystem Stats ---

pub fn df(fs) {
    let total_size = du(fs, "/")
    let file_count = len(find_by_kind(fs, "/", NODE_FILE))
    let dir_count = len(find_by_kind(fs, "/", NODE_DIR))

    {
        total_size: total_size,
        file_count: file_count,
        directory_count: dir_count,
        total_nodes: file_count + dir_count
    }
}

# --- Main Demo ---

fn main() {
    print("=== Arc Virtual Filesystem Demo ===\n")

    let mut fs = create_fs()

    # Build directory structure
    fs = fs
        |> mkdir_p("/home/alice", "alice")
        |> mkdir_p("/home/bob", "bob")
        |> mkdir_p("/home/alice/projects/arc-lang", "alice")
        |> mkdir_p("/home/alice/documents", "alice")
        |> mkdir_p("/etc/config", "root")
        |> mkdir_p("/var/log", "root")
        |> mkdir_p("/tmp", "root")

    # Create files
    fs = fs
        |> write_file("/home/alice/hello.txt", "Hello, World!\nThis is Alice's file.", "alice")
        |> write_file("/home/alice/projects/arc-lang/main.arc", "fn main() => print(\"Hello Arc!\")", "alice")
        |> write_file("/home/alice/projects/arc-lang/README.md", "# Arc Lang\nA modern programming language.", "alice")
        |> write_file("/home/bob/notes.txt", "Bob's notes\nTODO: Learn Arc", "bob")
        |> write_file("/etc/config/app.json", "\{\"port\": 8080\}", "root")
        |> write_file("/var/log/app.log", "2025-01-01 INFO: Server started\n2025-01-01 ERROR: Connection failed\n2025-01-02 INFO: Recovered", "root")

    # Create a symlink
    fs = fs |> ln_s("/home/alice/projects/arc-lang", "/home/alice/arc", "alice")

    print("--- Directory Tree ---")
    print("/")
    tree(fs, "/", "")

    # List files
    print("\n--- ls -la /home/alice ---")
    ls_la(fs, "/home/alice")

    # Read a file
    print("\n--- cat /home/alice/hello.txt ---")
    let content = read_file(fs, "/home/alice/hello.txt")
    if content.ok != nil { print(content.ok) }
    el { print("Error: {content.error}") }

    # Find files
    print("\n--- find / -name '*.arc' ---")
    let arc_files = find_by_name(fs, "/", "\\.arc$")
    for f in arc_files {
        print("  {f}")
    }

    # Grep
    print("\n--- grep 'ERROR' /var/log ---")
    let grep_matches = grep(fs, "/var/log", "ERROR")
    for m in grep_matches {
        print("  {m.file}:{m.line}: {m.text}")
    }

    # Disk usage
    print("\n--- Disk Usage ---")
    let stats = df(fs)
    print("Total size: {stats.total_size} bytes")
    print("Files: {stats.file_count}")
    print("Directories: {stats.directory_count}")

    # File operations
    print("\n--- File Operations ---")
    fs = fs |> cp("/home/alice/hello.txt", "/tmp/hello_copy.txt", "alice")
    print("Copied hello.txt to /tmp/")

    fs = fs |> append_file("/home/bob/notes.txt", "\nNew note: Arc is awesome!")
    print("Appended to Bob's notes")

    # Navigate
    fs = fs |> cd("/home/alice/projects")
    print("\nCurrent directory: {pwd(fs)}")

    print("\n--- ls (current dir) ---")
    ls_la(fs, ".")

    print("\nDone!")
}

main()
