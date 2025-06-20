# 🚀 Mori Ollama Stack (Open-WebUI + Ollama via Docker Compose)

This repository sets up a ready-to-use environment for running Ollama models with Open-WebUI, allowing local experimentation with LLMs using Docker Compose.

---

## 📦 Installation

```bash
git clone https://github.com/rafa-mori/mori-ollama-srv.git
cd mori-ollama-srv
make dev
```

To install using the advanced script with custom flags:

```bash
bash support/setup-dev.sh --light        # Use lightweight model
bash support/setup-dev.sh --no-benchmark # Skip benchmark step
bash support/setup-dev.sh --remote=user@host
```

Or simply use Make:

```bash
make install ARGS="--light"
make install ARGS="--remote=user@host"
```

---

## 🧠 Supported Models

| Model Name              | Description                                                                 |
|-------------------------|-----------------------------------------------------------------------------|
| `deepseek-coder:6.7b`  | Coding-focused LLM with structured responses. Great for code generation.   |
| `mistral`              | Lightweight general-purpose LLM. Lower RAM usage and faster loading.        |
| `llama`                | Meta's LLM family — generalist models with decent coding ability.           |

To change models:

```bash
make install ARGS="--light"          # Use mistral
make install ARGS="--no-benchmark"   # Skip testing
```

---

## 🛠️ Makefile Targets

| Command         | Description                                               |
|----------------|-----------------------------------------------------------|
| `make dev`     | Optimizes CPU + starts everything with recommended model. |
| `make up`      | Starts the Docker stack.                                  |
| `make pull`    | Pulls the default model (deepseek-coder:6.7b).            |
| `make run`     | Runs the model interactively (via CLI inside container).  |
| `make logs`    | Shows the WebUI logs.                                     |
| `make clean`   | Clean up all Docker artifacts and volumes.                |
| `make test`    | Re-runs setup-dev.sh with benchmarking.                   |
| `make help`    | Displays all available commands and options.              |

You can also pass flags like this:

```bash
make install ARGS="--remote=user@host"
make install ARGS="--light --no-benchmark"
```

---

## 📂 Project Structure

```plaintext
mori-ollama-srv/
├── docker-compose.yaml
├── support/
│   └── setup-dev.sh         # Main setup script
├── Makefile                 # Developer commands and automation
├── secrets/                 # Optional environment overrides
└── README.md
```

---

## 🔍 Benchmarking

The script auto-benchmarks response time on the first call to ensure your setup is responsive.
You can skip benchmarking with:

```bash
make install ARGS="--no-benchmark"
```

---

## 🌍 Access the UI

After starting:

> [http://localhost:3000](http://localhost:3000)

---

## 📄 License

MIT License — Rafael Mori (c) 2025

---

## 💬 Contributing

PRs, issues, and suggestions are always welcome!

---

## 📧 Contact

- GitHub: [@rafa-mori](https://github.com/rafa-mori)
- Site: [https://rafamori.pro](https://rafamori.pro)
