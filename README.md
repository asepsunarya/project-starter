# Project Starter

Starter untuk produk baru. Sudah berisi tiga starter sekaligus, jadi begitu
di-clone semuanya langsung aktif di Claude Code:

| dari | isi |
| --- | --- |
| [claude-starter](https://github.com/asepsunarya/claude-starter) | 25 skill engineering, 9 command (`/spec` `/plan` `/build` `/test` `/review` `/ship` ...), 4 subagent, checklist, rules, hooks |
| [replica-starter](https://github.com/asepsunarya/replica-starter) | 11 skill `/replica-*`, folder kerja `replica/`, 6 tool Python |
| [watermarks-starter](https://github.com/asepsunarya/watermarks-starter) | 2 skill pembersih tanda provenance AI, `service/`, hook PostToolUse, Docker |

## Mulai produk baru

```bash
git clone https://github.com/asepsunarya/project-starter.git produk-baru
cd produk-baru
rm -rf .git && git init
claude
```

Atau jadikan repo ini *template repository* di GitHub (Settings → Template
repository), lalu pakai tombol **Use this template**.

Setelah itu:

1. Isi bagian `[kurung]` di `CLAUDE.md` (nama project, tech stack, command).
2. Ganti `README.md` ini dengan README produk kamu.
3. Di Claude Code, mulai dari `/replica-recon https://app-yang-mau-di-clone.com`
   atau dari `/spec` kalau produknya bukan clone.

Yang dibutuhkan: Python 3.10+. `make test` butuh `pytest`. Docker opsional.

## Alur kerja

Clone sebuah aplikasi (Replica), berurutan:

```
recon -> architect -> design -> build -> backend -> test -> diff -> entrepreneur -> brand -> launch -> deploy
```

Setiap tahap adalah skill `/replica-<tahap>` dan membaca hasil tahap
sebelumnya di `replica/`. Replica membangun ulang **apa yang dilakukan**
aplikasi, bukan kode, logo, copy, atau kontennya.

Disiplin kode (claude-starter), dipakai di dalam tahap build maupun untuk
fitur baru:

```
/spec -> /plan -> /build -> /test -> /review -> /ship
```

Konten (Watermarks):

```
/remove-ai-marks work/in/draft.md          # butuh service: make serve
/clean-user-facing-text work/in/artikel.md # mandiri
```

Untuk konten yang kamu miliki atau berwenang memprosesnya. Bukan untuk
menyembunyikan bantuan AI di tempat yang mewajibkan disclosure.

## Hook otomatis

`.claude/settings.json` memasang hook PostToolUse: setiap kali Claude menulis
atau mengedit file, `service/scripts/hook_written_file.py` memeriksanya dan
melaporkan tanda provenance yang ditemukan. Mode default `check` tidak mengubah
file. Ganti `--mode check` menjadi `--mode clean` kalau mau dibersihkan
otomatis, atau hapus blok hook itu kalau tidak dipakai.

Dua hook opsional dari claude-starter (`sdd-cache`, `simplify-ignore`) ada di
`.claude/hooks/` tetapi belum didaftarkan. Cara mengaktifkannya ada di
`.claude/hooks/SDD-CACHE.md` dan `.claude/hooks/SIMPLIFY-IGNORE.md`.

## Struktur

```
.claude/
  skills/                    38 skill: 25 engineering, 11 replica-*, 2 watermarks
  commands/ agents/ references/ rules/ hooks/
  settings.json              hook PostToolUse watermarks (mode check)
CLAUDE.md                    instruksi project untuk Claude (isi bagian [kurung])
replica/                     folder kerja Replica
service/                     mesin pembersih + HTTP server Watermarks
config/clean_strategy.json   strategi rewrite default
work/in, work/out            file yang dibersihkan (tidak di-commit)
tests/replica/               unit test tool Replica (unittest)
tests/watermarks/            unit test service Watermarks (pytest)
compose.yaml                 service Watermarks lewat Docker
Makefile                     shortcut gabungan, lihat `make help`
scripts/sync-starters.sh     tarik ulang isi dari tiga starter sumber
STARTERS.lock                commit sumber dari sync terakhir
```

## Tool

```bash
make help                          # semua shortcut
make test                          # unit test replica + watermarks
make parity                        # skor parity dari replica/features.csv
make sweep AVOID='Nama App Asli'   # sisa brand asli di codebase?
make serve                         # service watermarks di http://127.0.0.1:8765
make inspect FILE=work/in/foto.jpg # laporan tanda pada satu file
make clean FILE=work/in/foto.jpg   # bersihkan -> work/out/foto.jpg
```

## Memperbarui dari starter sumber

```bash
make sync
make test
git status
```

`scripts/sync-starters.sh` meng-clone ketiga repo sumber dan menyalin ulang
isinya. Untuk memakai checkout lokal, set `CLAUDE_STARTER`, `REPLICA_STARTER`,
dan `WATERMARKS_STARTER` ke path-nya.

| jenis | file | saat sync |
| --- | --- | --- |
| vendored | `.claude/skills/*`, `commands`, `agents`, `references`, `hooks`, `UPSTREAM.md`, `service/`, `tests/replica/`, `tests/watermarks/` | ditimpa |
| seed | `.claude/rules/`, `replica/`, `config/`, `work/`, `compose.yaml`, `.env.example` | disalin hanya kalau belum ada |
| milik repo ini | `CLAUDE.md`, `README.md`, `Makefile`, `.gitignore`, `LICENSE`, `pytest.ini`, `.claude/settings.json` | tidak disentuh |

Jangan edit file vendored secara manual; perubahan akan hilang saat sync
berikutnya. Skill yang kamu tambahkan sendiri di `.claude/skills/` aman.
Kalimat di `.claude/UPSTREAM.md` soal `install.ps1` berlaku untuk repo
claude-starter; di sini cukup `make sync`.

## Lisensi

MIT, lihat [LICENSE](LICENSE). Skill engineering dari
[addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), Replica
skill pack oleh [Jake Schincariol](https://github.com/Jakeschincariol/replica-skill),
watermarks-remover oleh [Guillaume Meyer](https://github.com/guillaumemeyer/watermarks-remover)
dan kontributor.
