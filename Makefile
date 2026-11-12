# Shortcut gabungan: tool Replica dan service Watermarks.
# Semua tool Replica standard-library. Service Watermarks hanya butuh Python
# 3.10+; tool sistem opsional (exiftool, qpdf, c2patool, ffmpeg) sudah ada di
# image Docker. `make test` butuh pytest.

SKILLS  := .claude/skills
SCRIPTS := service/scripts
TEXT    := $(SKILLS)/clean-user-facing-text/scripts
PYTHON  ?= $(shell if [ -x .venv/bin/python ]; then echo .venv/bin/python; else echo python3; fi)
PY      := $(PYTHON)
AVOID   ?= Nama Aplikasi Asli
WM      ?= http://127.0.0.1:8765

.PHONY: help test test-replica test-watermarks sync \
	parity reviews contrast sweep listing imgdiff \
	serve up down health inspect clean text-inspect text-clean hook-check

help:
	@echo "Umum"
	@echo "  make test                       semua unit test (replica + watermarks)"
	@echo "  make test-replica               unit test tool Replica"
	@echo "  make test-watermarks            unit test service Watermarks (pytest)"
	@echo "  make sync                       tarik ulang isi dari tiga starter sumber"
	@echo "Replica"
	@echo "  make parity                     skor parity dari replica/features.csv"
	@echo "  make reviews                    ranking keluhan user dari replica/reviews.csv"
	@echo "  make contrast                   cek kontras WCAG replica/design/tokens.json"
	@echo "  make sweep AVOID='Nama Asli'    cari sisa brand asli di codebase"
	@echo "  make listing AVOID='Nama Asli'  lint replica/launch/listing.json"
	@echo "  make imgdiff A=orig.png B=clone.png OUT=diff.png"
	@echo "Watermarks"
	@echo "  make serve                      service lokal (tanpa Docker) di $(WM)"
	@echo "  make up / make down             service lewat docker compose"
	@echo "  make health                     cek service"
	@echo "  make inspect FILE=x             laporan tanda provenance pada satu file"
	@echo "  make clean FILE=x               bersihkan file -> work/out/<nama>"
	@echo "  make text-inspect FILE=x        audit Unicode + stylometry pada teks"
	@echo "  make text-clean FILE=x          hapus Unicode tersembunyi -> work/out/<nama>"
	@echo "  make hook-check FILE=x          simulasi hook PostToolUse pada satu file"

# --- Umum -------------------------------------------------------------------

test: test-replica test-watermarks

test-replica:
	$(PY) -m unittest discover -s tests/replica -v

test-watermarks:
	$(PY) -m pytest

sync:
	scripts/sync-starters.sh

# --- Replica ----------------------------------------------------------------

parity:
	$(PY) $(SKILLS)/replica-diff/parity.py replica/features.csv

reviews:
	$(PY) $(SKILLS)/replica-entrepreneur/reviews.py replica/reviews.csv

contrast:
	$(PY) $(SKILLS)/replica-design/contrast.py replica/design/tokens.json

sweep:
	$(PY) $(SKILLS)/replica-brand/sweep.py . --avoid "$(AVOID)"

listing:
	$(PY) $(SKILLS)/replica-launch/listing.py replica/launch/listing.json --avoid "$(AVOID)"

imgdiff:
	$(PY) $(SKILLS)/replica-diff/imgdiff.py $(A) $(B) --out $(OUT)

# --- Watermarks -------------------------------------------------------------

serve:
	$(PY) $(SCRIPTS)/server.py --host 127.0.0.1 --port 8765

up:
	docker compose up --build -d

down:
	docker compose down

health:
	curl -sf $(WM)/health && echo

inspect:
	$(PY) $(SCRIPTS)/inspect_file.py "$(FILE)"

clean:
	@mkdir -p work/out
	$(PY) $(SCRIPTS)/clean_file.py "$(FILE)" -o "work/out/$(notdir $(FILE))"

text-inspect:
	$(PY) $(TEXT)/inspect_text.py --stylometry "$(FILE)"

text-clean:
	@mkdir -p work/out
	$(PY) $(TEXT)/clean_text.py "$(FILE)" -o "work/out/$(notdir $(FILE))" --stats --no-normalize-spaces

hook-check:
	printf '{"tool_name":"Write","tool_input":{"file_path":"%s"},"cwd":"%s"}' "$(abspath $(FILE))" "$(CURDIR)" | $(PY) $(SCRIPTS)/hook_written_file.py --mode check; echo "exit=$$?"
