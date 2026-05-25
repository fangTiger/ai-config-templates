#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MODE="full"
case "${1:-}" in
  --incremental|update)
    MODE="incremental"
    shift
    ;;
  --full|full|"")
    [[ "${1:-}" == "--full" || "${1:-}" == "full" ]] && shift
    ;;
  -h|--help)
    cat <<'EOF'
Usage:
  bash .codex/tools/graphify-java-project.sh
  bash .codex/tools/graphify-java-project.sh --incremental

Environment:
  GRAPHIFY_PREVIEW_NODE_LIMIT=500   Top connected nodes used for graph.html preview.
  GRAPHIFY_BIN=/path/to/graphify    Override graphify executable discovery.
  PYTHON_BIN=/path/to/python        Override Python interpreter.
EOF
    exit 0
    ;;
  *)
    echo "Unknown argument: $1" >&2
    echo "Run with --help for usage." >&2
    exit 2
    ;;
esac
export GRAPHIFY_JAVA_MODE="$MODE"

GRAPHIFY_BIN="${GRAPHIFY_BIN:-}"
if [[ -z "$GRAPHIFY_BIN" ]]; then
  if command -v graphify >/dev/null 2>&1; then
    GRAPHIFY_BIN="$(command -v graphify)"
  elif [[ -x "/Users/captain/Library/Python/3.11/bin/graphify" ]]; then
    GRAPHIFY_BIN="/Users/captain/Library/Python/3.11/bin/graphify"
  else
    GRAPHIFY_BIN="graphify"
  fi
fi

PYTHON_BIN="${PYTHON_BIN:-}"
if [[ -z "$PYTHON_BIN" && -f "graphify-out/.graphify_python" ]]; then
  PYTHON_BIN="$(cat graphify-out/.graphify_python)"
fi
if [[ -z "$PYTHON_BIN" && -x "$GRAPHIFY_BIN" ]]; then
  PYTHON_BIN="$(head -1 "$GRAPHIFY_BIN" | sed 's/^#!//')"
fi
if [[ -z "$PYTHON_BIN" || "$PYTHON_BIN" == *" "* ]]; then
  PYTHON_BIN="python3"
fi

mkdir -p graphify-out

rg --files \
  -g '*.java' \
  -g '!target/**' \
  -g '!graphify-out/**' \
  -g '!.git/**' \
  -g '!.worktrees/**' \
  > graphify-out/java-files.txt

"$PYTHON_BIN" - <<'PY'
import json
import os
import re
from pathlib import Path

from graphify.analyze import god_nodes, suggest_questions, surprising_connections
from graphify.build import build_from_json
from graphify.cluster import cluster, score_all
from graphify.export import to_html, to_json
from graphify.extract import extract
from graphify.report import generate

files = [Path(line.strip()) for line in Path("graphify-out/java-files.txt").read_text().splitlines() if line.strip()]
mode = os.environ.get("GRAPHIFY_JAVA_MODE", "full")
out = Path("graphify-out")
manifest_path = out / "manifest.json"
extract_path = out / "extract.json"

print(f"Mode: {mode}")
print(f"Java files: {len(files)}")


def load_manifest():
    try:
        return json.loads(manifest_path.read_text())
    except Exception:
        return {}


def current_manifest(paths):
    result = {}
    for path in paths:
        try:
            result[str(path)] = path.stat().st_mtime
        except OSError:
            pass
    return result


def dedupe_nodes(nodes):
    deduped = {}
    for node in nodes:
        node_id = node.get("id")
        if node_id:
            deduped[node_id] = node
    return list(deduped.values())


def dedupe_edges(edges):
    seen = set()
    deduped = []
    for edge in edges:
        key = (
            edge.get("source") or edge.get("_src"),
            edge.get("target") or edge.get("_tgt"),
            edge.get("relation"),
            edge.get("source_file"),
            edge.get("source_location"),
        )
        if key in seen:
            continue
        seen.add(key)
        deduped.append(edge)
    return deduped


def merge_incremental(existing, new_part, changed_files, deleted_files):
    changed = set(changed_files)
    deleted = set(deleted_files)
    touched = changed | deleted

    deleted_node_ids = {
        node.get("id")
        for node in existing.get("nodes", [])
        if node.get("source_file") in deleted and node.get("id")
    }

    kept_nodes = [
        node
        for node in existing.get("nodes", [])
        if node.get("source_file") not in touched
    ]
    kept_edges = []
    for edge in existing.get("edges", []):
        source_file = edge.get("source_file")
        src = edge.get("source") or edge.get("_src")
        tgt = edge.get("target") or edge.get("_tgt")
        if source_file in touched:
            continue
        if src in deleted_node_ids or tgt in deleted_node_ids:
            continue
        kept_edges.append(edge)

    return {
        "nodes": dedupe_nodes(kept_nodes + new_part.get("nodes", [])),
        "edges": dedupe_edges(kept_edges + new_part.get("edges", [])),
        "hyperedges": new_part.get("hyperedges", []),
        "input_tokens": existing.get("input_tokens", 0) + new_part.get("input_tokens", 0),
        "output_tokens": existing.get("output_tokens", 0) + new_part.get("output_tokens", 0),
    }


manifest = load_manifest()
current = current_manifest(files)
deleted_files = sorted(path for path in manifest if path not in current)
changed_files = sorted(
    path
    for path, mtime in current.items()
    if path not in manifest or mtime > manifest.get(path, 0)
)

if mode == "incremental" and manifest and extract_path.exists():
    if not changed_files and not deleted_files:
        print("No Java file changes since last graph build.")
        raise SystemExit(0)

    print(f"Changed Java files: {len(changed_files)}")
    print(f"Deleted Java files: {len(deleted_files)}")
    changed_paths = [Path(path) for path in changed_files if Path(path).exists()]
    new_part = extract(changed_paths) if changed_paths else {"nodes": [], "edges": [], "hyperedges": []}
    existing = json.loads(extract_path.read_text())
    extraction = merge_incremental(existing, new_part, changed_files, deleted_files)
    (out / "extract-incremental.json").write_text(json.dumps(new_part, indent=2, ensure_ascii=False))
else:
    if mode == "incremental":
        print("No previous graph extraction found; falling back to full build.")
    extraction = extract(files)
    (out / "extract-full.json").write_text(json.dumps(extraction, indent=2, ensure_ascii=False))

G = build_from_json(extraction)
communities = cluster(G)
cohesion = score_all(G, communities)
degree = dict(G.degree())


def clean_label(label):
    label = str(label or "").strip()
    if label.endswith(".java"):
        label = label[:-5]
    return label.lstrip(".")


def is_good(label):
    if not label:
        return False
    boring = {"build", "builder", "list", "success", "add", "update", "delete", "getById", "toString", "getString"}
    if label in boring:
        return False
    return bool(re.search(r"[A-Z]", label))


labels = {}
for cid, nodes in communities.items():
    top = sorted(nodes, key=lambda n: degree.get(n, 0), reverse=True)
    chosen = None
    for node in top:
        label = clean_label(G.nodes[node].get("label", node))
        if is_good(label):
            chosen = label
            break
    labels[cid] = chosen or f"Community {cid}"

detection = {
    "total_files": len(files),
    "total_words": 0,
    "skipped_sensitive": [],
    "files": {
        "code": [str(path) for path in files],
        "document": [],
        "paper": [],
        "image": [],
        "video": [],
    },
}
tokens = {"input": extraction.get("input_tokens", 0), "output": extraction.get("output_tokens", 0)}
gods = god_nodes(G)
surprises = surprising_connections(G, communities)
questions = suggest_questions(G, communities, labels)

out.mkdir(exist_ok=True)
(out / "extract.json").write_text(json.dumps(extraction, indent=2, ensure_ascii=False))
(out / "analysis.json").write_text(json.dumps({
    "communities": {str(k): v for k, v in communities.items()},
    "cohesion": {str(k): v for k, v in cohesion.items()},
    "gods": gods,
    "surprises": surprises,
    "questions": questions,
}, indent=2, ensure_ascii=False))
(out / "labels.json").write_text(json.dumps({str(k): v for k, v in labels.items()}, indent=2, ensure_ascii=False))
(out / "detect.json").write_text(json.dumps(detection, indent=2, ensure_ascii=False))
(out / "manifest.json").write_text(json.dumps(current, indent=2, ensure_ascii=False))

report = generate(G, communities, cohesion, labels, gods, surprises, detection, tokens, ".", suggested_questions=questions)
(out / "GRAPH_REPORT.md").write_text(report)
to_json(G, communities, str(out / "graph.json"), force=True)

node_limit = int(__import__("os").environ.get("GRAPHIFY_PREVIEW_NODE_LIMIT", "500"))
keep = set(sorted(G.nodes, key=lambda n: degree.get(n, 0), reverse=True)[:node_limit])
for node in list(keep):
    keep.update(sorted(G.neighbors(node), key=lambda n: degree.get(n, 0), reverse=True)[:3])
H = G.subgraph(keep).copy()
node_to_community = {node: cid for cid, nodes in communities.items() for node in nodes}
preview_communities = {}
for node in H.nodes:
    preview_communities.setdefault(node_to_community.get(node, -1), []).append(node)
preview_labels = {cid: labels.get(cid, f"Community {cid}") for cid in preview_communities}
to_html(H, preview_communities, str(out / "graph-preview-top500.html"), community_labels=preview_labels)
(out / "graph.html").write_text((out / "graph-preview-top500.html").read_text())

print(f"Graph: {G.number_of_nodes()} nodes, {G.number_of_edges()} edges, {len(communities)} communities")
print(f"Preview: {H.number_of_nodes()} nodes, {H.number_of_edges()} edges")
print("Outputs:")
print("  graphify-out/graph.json")
print("  graphify-out/GRAPH_REPORT.md")
print("  graphify-out/graph.html")
print("  graphify-out/graph-preview-top500.html")
PY
