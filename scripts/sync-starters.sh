#!/usr/bin/env bash
# Tarik ulang isi tiga starter sumber ke repo ini.
#
#   scripts/sync-starters.sh                 # clone ketiganya dari GitHub
#   CLAUDE_STARTER=../claude-starter \
#   REPLICA_STARTER=../replica-starter \
#   WATERMARKS_STARTER=../watermarks-starter scripts/sync-starters.sh
#
# Dua jenis file:
#   vendored  ditimpa setiap sync (skill, command, agent, service, test)
#   seed      disalin hanya kalau belum ada, tidak pernah ditimpa
#             (.claude/rules, replica/, config/, compose.yaml, .env.example)
#
# File milik repo ini (CLAUDE.md, README.md, Makefile, .gitignore, LICENSE,
# pytest.ini, .claude/settings.json) tidak disentuh.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OWNER_URL="${STARTERS_BASE_URL:-https://github.com/asepsunarya}"
TMP=""
trap '[ -n "$TMP" ] && rm -rf "$TMP"' EXIT

# source <nama> <path lokal atau kosong> -> cetak path checkout
source_dir() {
  local name="$1" local_path="$2"
  if [ -n "$local_path" ]; then
    [ -d "$local_path" ] || { echo "tidak ada: $local_path" >&2; exit 1; }
    (cd "$local_path" && pwd)
    return
  fi
  [ -n "$TMP" ] || TMP="$(mktemp -d)"
  git clone -q --depth 1 "$OWNER_URL/$name.git" "$TMP/$name" >&2
  echo "$TMP/$name"
}

sha_of() { git -C "$1" rev-parse HEAD 2>/dev/null || echo "unknown"; }

# Ganti folder tujuan dengan salinan folder sumber.
vendor_dir() {
  local src="$1" dst="$2"
  [ -d "$src" ] || { echo "sumber hilang: $src" >&2; exit 1; }
  rm -rf "$dst"
  mkdir -p "$(dirname "$dst")"
  cp -R "$src" "$dst"
}

# Salin setiap skill dari sumber; skill lain di tujuan dibiarkan.
vendor_skills() {
  local src="$1" skill
  for skill in "$src"/*/; do
    vendor_dir "${skill%/}" "$ROOT/.claude/skills/$(basename "$skill")"
  done
}

# Salin file atau folder hanya kalau tujuannya belum ada.
seed() {
  local src="$1" dst="$2" rel
  if [ -d "$src" ]; then
    (cd "$src" && find . -type f) | while IFS= read -r rel; do
      seed "$src/$rel" "$dst/$rel"
    done
  elif [ ! -e "$dst" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
  fi
}

CLAUDE="$(source_dir claude-starter "${CLAUDE_STARTER:-}")"
REPLICA="$(source_dir replica-starter "${REPLICA_STARTER:-}")"
WATERMARKS="$(source_dir watermarks-starter "${WATERMARKS_STARTER:-}")"

mkdir -p "$ROOT/.claude/skills"

# --- claude-starter: isi template/.claude ---------------------------------
vendor_skills "$CLAUDE/template/.claude/skills"
for d in commands agents references hooks; do
  vendor_dir "$CLAUDE/template/.claude/$d" "$ROOT/.claude/$d"
done
cp "$CLAUDE/template/.claude/UPSTREAM.md" "$ROOT/.claude/UPSTREAM.md"
seed "$CLAUDE/template/.claude/rules" "$ROOT/.claude/rules"

# --- replica-starter -------------------------------------------------------
vendor_skills "$REPLICA/.claude/skills"
vendor_dir "$REPLICA/tests" "$ROOT/tests/replica"
seed "$REPLICA/replica" "$ROOT/replica"
# Test pindah satu tingkat lebih dalam: tests/ -> tests/replica/.
sed -i.bak 's/os\.path\.dirname(os\.path\.dirname(os\.path\.abspath(__file__)))/os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))/' \
  "$ROOT/tests/replica/_load.py"

# --- watermarks-starter ----------------------------------------------------
vendor_skills "$WATERMARKS/.claude/skills"
vendor_dir "$WATERMARKS/service" "$ROOT/service"
vendor_dir "$WATERMARKS/tests" "$ROOT/tests/watermarks"
seed "$WATERMARKS/config" "$ROOT/config"
seed "$WATERMARKS/work" "$ROOT/work"
seed "$WATERMARKS/compose.yaml" "$ROOT/compose.yaml"
seed "$WATERMARKS/.env.example" "$ROOT/.env.example"
# Test pindah satu tingkat lebih dalam: tests/ -> tests/watermarks/.
find "$ROOT/tests/watermarks" -name '*.py' -exec sed -i.bak \
  -e 's/resolve()\.parents\[1\]/resolve().parents[2]/g' \
  -e 's/resolve()\.parent\.parent/resolve().parents[2]/g' \
  -e 's#"tests" / "fixtures"#"tests" / "watermarks" / "fixtures"#g' \
  -e 's/^from tests\.test_/from tests.watermarks.test_/' {} +

find "$ROOT/tests" -name '*.bak' -delete
find "$ROOT/tests" "$ROOT/service" "$ROOT/.claude" -name '__pycache__' -type d -prune -exec rm -rf {} +

cat > "$ROOT/STARTERS.lock" <<EOF
# Commit sumber dari sync terakhir. Ditulis oleh scripts/sync-starters.sh.
claude-starter      $(sha_of "$CLAUDE")
replica-starter     $(sha_of "$REPLICA")
watermarks-starter  $(sha_of "$WATERMARKS")
EOF

echo "sync selesai. Jalankan 'make test', lalu periksa 'git status'."
