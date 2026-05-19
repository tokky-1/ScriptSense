# ScriptSense — Handwriting to Document Converter

ScriptSense takes photos of handwritten text and converts them into clean, editable documents (PDF, DOCX, or TXT). An ML pipeline handles the heavy lifting: a YOLO model segments each line of handwriting, TrOCR transcribes the text, and an optional Ollama NLP layer polishes the result.

---

## How It Works

```
Uploaded images
  │
  ├── Image processing    — EXIF correction, perspective de-skew, binarization
  ├── Line detection      — YOLO segments each handwritten line into crops
  ├── Handwriting OCR     — TrOCR (microsoft/trocr-large-handwritten) reads each crop
  ├── NLP polish          — Ollama fixes common OCR misreads (optional)
  └── File creation       — Output packaged as PDF / DOCX / TXT
```

Two conversion modes:

- **Multi-page** — all uploaded images become pages of one combined document
- **Separate documents** — each image becomes its own independent file

Progress is streamed to the browser in real time via Server-Sent Events (SSE).

---

## Features

### Capabilities

- **Multi-format output** — Export to PDF, DOCX, or TXT
- **Flexible document modes** — Combine multiple images into one document or save each separately
- **Real-time progress** — SSE streaming shows pipeline status as images are processed
- **Batch processing** — Handle up to 30 images per request
- **Optional NLP polishing** — Use Ollama to correct OCR mistakes and improve readability
- **EXIF correction** — Automatically rotates images to correct orientation
- **Perspective correction** — De-skews angled handwritten pages
- **Binarization** — Enhances contrast for cleaner OCR results

### Supported Input

- **Image formats** — JPEG, PNG, WebP, BMP, TIFF
- **File size** — Up to 50 MB per image; 30 images per batch
- **Handwriting style** — Printed text and cursive, mixed within a single document
- **English language** 

### Output Quality

- **Accuracy** — Typical 85–95% character accuracy on clear, well-lit handwriting
- **Processing time** — ~1 minute per image on modern GPUs; ~2-3 minutes on CPU
- **Editability** — Output documents are fully editable (DOCX) or selectable (PDF)

---

## Limitations

### System Constraints

| Constraint              | Value                             | Notes                                              |
| ----------------------- | --------------------------------- | -------------------------------------------------- |
| Max file size per image | 50 MB                             | Set via `MAX_UPLOAD_SIZE_MB`                       |
| Max images per batch    | 30                                | Set via `MAX_IMAGES_PER_REQUEST`                   |
| Total processing time   | Varies                            | ~1 min per image on GPU; ~2-3 min on CPU             |
| Temporary storage       | `/tmp/scriptsense` (configurable) | Cleared after job completion                       |
| Concurrent jobs         | 1 (single instance)               | Scale horizontally with multiple backend instances |

### Handwriting & OCR Limitations

- **Handwriting quality** — Performs best on clear, well-spaced, legible handwriting; degrades on cramped or heavily slanted text
- **Background noise** — Poor OCR on complex backgrounds, stains, annotations, coloured paper, torn paper 
- **Mathematical equations and Diagrams**
- **Language support** — English scripts only
- **Cursive complexity** — Connected cursive with unusual flourishes may have lower accuracy
- **Character accuracy** — Typical 85–95% on standard handwriting; drops to 60–80% on challenging inputs

### Model Limitations

- **YOLO line detection** — May struggle with very dense text, overlapping lines, or extreme angles (>45°)
- **TrOCR accuracy** — Pre-trained on printed and standard cursive; does not learn from user corrections
- **NLP polishing** — Ollama corrections require a locally running Ollama instance and depend on its model configuration

### Deployment & Performance

- **GPU memory** — Requires ~4–6 GB VRAM for TrOCR inference; scales to CPU with longer processing times
- **Storage** — TrOCR model (~2.2 GB) + YOLO weights (~100 MB) required on disk
- **Scalability** — Single backend instance; horizontal scaling requires coordinating job queues
- **No persistence** — Processed files are temporary; must be downloaded before job completion

### Known Issues
- **line duplication** — YOLO sometimes send duplicate crops of the same line of text
- **SSE disconnections** — Long-running jobs may timeout with some reverse proxies
- **Large batches** — Processing 30 images simultaneously may cause memory pressure on systems with <8 GB RAM
- **Model updates** — TrOCR model is not automatically updated; manual refresh required for newer versions

---

## Project Structure

```
project-root/
├── pyproject.toml          # uv workspace root
├── uv.lock                 # single Python lockfile
├── Makefile                # common commands (make)
├── Justfile                # common commands (just)
├── start.sh                # starts all services in dev mode
├── docker-compose.yml      # container orchestration
├── scripts/
│   └── save_model_locally.py   # one-time TrOCR model download
│
├── frontend/               # React + Vite application
├── backend/                # FastAPI application
└── model/
    └── saved_models/
        ├── line_detector_best.pt   # YOLO line segmentation weights
        └── trocr/                  # TrOCR model (downloaded on first run)
```

See each folder's own `README.md` for detailed setup:

- [frontend/README.md](frontend/README.md)
- [backend/README.md](backend/README.md)
- [model/README.md](model/README.md)

---

## Prerequisites

| Tool                             | Purpose                          |
| -------------------------------- | -------------------------------- |
| Node.js >= 18                    | Frontend                         |
| Python >= 3.11                   | Backend + Model                  |
| [uv](https://docs.astral.sh/uv/) | Python dependency management     |
| conda / miniconda                | Model GPU/system deps            |
| Docker + Docker Compose          | Containerised startup (optional) |

---

## Quick Start — Local Dev

`start.sh` brings up the frontend and backend together. On first run it checks whether the TrOCR model has been saved locally — if not, it downloads it (~2.2 GB, one time only) before starting the backend.

**1. Install dependencies:**

```bash
make install
# or: just install
```

**2. Copy and fill in environment files:**

```bash
make env_copy
# or: just env_copy
```

Populate at minimum:

- `backend/.env` — `SECRET_KEY`, `OLLAMA_API_KEY` (if using NLP polish)
- `frontend/.env` — already configured for local dev out of the box

**3. Start all services:**

```bash
bash start.sh
# or: make dev  /  just dev
```

| Service  | URL                        |
| -------- | -------------------------- |
| Frontend | http://localhost:5173      |
| Backend  | http://localhost:8000      |
| API Docs | http://localhost:8000/docs |

Press `Ctrl+C` to stop all services cleanly.

---

## Model Setup

The YOLO weights (`line_detector_best.pt`) is placed in `model/saved_models/`.

The TrOCR model is downloaded automatically on first startup via `scripts/save_model_locally.py` and saved to `model/saved_models/trocr/`. Subsequent startups load from that local directory — no internet required.

To trigger the download manually:

```bash
uv run python scripts/save_model_locally.py
```

---

## Quick Start — Docker

**1. Copy environment files:**

```bash
cp frontend/.env.example frontend/.env
cp backend/.env.example backend/.env
```

**2. Build and start:**

```bash
make build && make up
# or: docker-compose up --build
```

**3. Stop:**

```bash
make down
# or: docker-compose down
```

The `backend` container mounts `model/saved_models/` from the host so model artifacts are shared without rebuilding the image.

---

## Environment Variables

### Backend (`backend/.env`)

| Variable                 | Default                                       | Description                                       |
| ------------------------ | --------------------------------------------- | ------------------------------------------------- |
| `APP_ENV`                | `development`                                 | `development` enables `/docs` and `/redoc`        |
| `APP_PORT`               | `8000`                                        | Port uvicorn binds to                             |
| `SECRET_KEY`             | —                                             | App secret — change before deploying              |
| `ALLOWED_ORIGINS`        | `http://localhost:5173`                       | Comma-separated CORS origins                      |
| `YOLO_MODEL_PATH`        | `../model/saved_models/line_detector_best.pt` | YOLO weights                                      |
| `TROCR_MODEL_NAME`       | `../model/saved_models/trocr`                 | TrOCR local path or HuggingFace model ID          |
| `OLLAMA_API_KEY`         | —                                             | Enables NLP post-processing via Ollama (optional) |
| `MAX_UPLOAD_SIZE_MB`     | `50`                                          | Per-file upload limit                             |
| `MAX_IMAGES_PER_REQUEST` | `30`                                          | Maximum images per conversion job                 |
| `TEMP_DIR`               | `/tmp/scriptsense`                            | Scratch space for in-progress jobs                |

### Frontend (`frontend/.env`)

| Variable            | Default    | Description                                                                  |
| ------------------- | ---------- | ---------------------------------------------------------------------------- |
| `VITE_API_BASE_URL` | `` (empty) | Leave empty to use the Vite dev proxy; set to a full URL for remote backends |
| `VITE_MOCK_API`     | `false`    | Set to `true` to bypass the backend and use mock data                        |

---

## API Overview

| Method | Endpoint                                  | Description                                          |
| ------ | ----------------------------------------- | ---------------------------------------------------- |
| `GET`  | `/health`                                 | Health check                                         |
| `POST` | `/api/convert`                            | Start a conversion job — returns `job_id` (HTTP 202) |
| `GET`  | `/api/convert/{job_id}/progress`          | SSE stream of pipeline progress events               |
| `GET`  | `/api/convert/{job_id}/result/{filename}` | Download a completed output file                     |

---

## Commands Reference

Both `make` and `just` run the same operations. Install `just` with `brew install just`.

| Command                         | Description                                         |
| ------------------------------- | --------------------------------------------------- |
| `make install` / `just install` | Install frontend (npm) and Python (uv) dependencies |
| `make dev` / `just dev`         | Start all services in dev mode                      |
| `make build` / `just build`     | Build Docker images                                 |
| `make up` / `just up`           | Start all Docker containers                         |
| `make down` / `just down`       | Stop all Docker containers                          |
| `make train` / `just train`     | Run model training                                  |
| `make clean` / `just clean`     | Remove build artifacts and caches                   |

---

## How the Services Connect

```
Browser
  └── Frontend (React :5173)
        └── /api/* proxied in dev → Backend (FastAPI :8000)
                                      ├── YOLO model (line detection)
                                      ├── TrOCR model (handwriting OCR)
                                      ├── Ollama (NLP polish, optional)
                                      └── model/saved_models/
```

During development the Vite dev server proxies all `/api/*` requests to the FastAPI backend, so the frontend and backend appear as a single origin — no CORS configuration needed on the client.
