# 🚀 Open-WebUI + Ollama with Docker Compose

This project provides a ready-to-use environment to run [Open-WebUI](https://github.com/open-webui/open-webui) alongside [Ollama](https://ollama.com/) using Docker Compose. It enables local testing of powerful LLMs with a simple setup and a clean web interface — no local installation of Ollama required on your host machine.

---

## 📦 Installation and Execution

1. **Clone this repository**:
   ```bash
   git clone https://github.com/faelmori/mori-ollama-srv.git
   cd mori-ollama-srv
   ```

2. **Run the installation script**:

   ```bash
   bash ./install.sh
   ```

3. **Access the WebUI**:
   Open your browser and go to: [http://localhost:3000](http://localhost:3000)

---

## 🧠 Supported Models

The Ollama service supports a variety of open-source models. Below are some popular ones:

| Model            | Description                                                                                |
| ---------------- | ------------------------------------------------------------------------------------------ |
| `llama3:latest`  | Meta’s flagship model with excellent contextual understanding.                             |
| `mistral:latest` | Lightweight and fast model, great for resource-constrained environments.                   |
| `deepseek-coder` | Code-oriented model ideal for autocompletion, code generation, and developer productivity. |
| `deepseek-llm`   | General-purpose reasoning model from DeepSeek.                                             |
| `gemma:latest`   | Google's open-source conversational model.                                                 |
| `phi3:latest`    | Efficient model from Microsoft, ideal for local/edge deployments.                          |

---

## 🐳 Docker Compose Services

* **llm-ui**: Runs the Open-WebUI frontend.
* **llm-app**: Runs the Ollama backend responsible for model execution.

---

## 🛠️ Configuration

* **Volumes**:

  * `llm-ui-vol`: Persists WebUI data (user preferences, history, etc.).
  * `llm-app-vol`: Stores downloaded models and Ollama runtime data.

* **Networks**:

  * `hub-ass-priv-net`: Internal communication network between services.
  * `hub-ass-pub-net`: Public-facing network for browser access.

---

## 📂 Project Structure

```
mori-ollama-srv/
├── docker-compose.yaml        # Defines services and networks
├── install.sh                 # Setup automation script
├── secrets/
│   ├── .llm.ui.dev.env        # WebUI development config
│   ├── .llm.ui.prd.env        # WebUI production config
│   ├── .llm.app.dev.env       # Ollama development config
│   ├── .llm.app.prd.env       # Ollama production config
└── README.md
```

---

## 🧰 Using Ollama CLI (Inside Docker)

Since Ollama runs inside a Docker container, the CLI must be accessed **inside the container**.

### ➤ Run a model:

```bash
docker exec -it llm-app ollama run llama3
```

### ➤ Pull a model manually:

```bash
docker exec -it llm-app ollama pull deepseek-coder
```

### ➤ Open a shell inside the container:

```bash
docker exec -it llm-app bash
# or 'sh' if bash is not available
```

### 🔁 Optional: Create an alias (recommended)

To simplify repeated use, you can add this to your `.bashrc` or `.zshrc`:

```bash
alias ollamac="docker exec -it llm-app ollama"
```

Now you can use:

```bash
ollamac run mistral
ollamac pull llama3
```

---

## ✅ Requirements

* Docker and Docker Compose installed
* 8GB+ RAM recommended
* Around 2GB+ disk space per model

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for full details.

---

## 🌟 Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request to improve the project or suggest new features.

---

## 📧 Contact

For inquiries, suggestions, or collaboration opportunities, contact [rafa-mori](https://github.com/rafa-mori).
