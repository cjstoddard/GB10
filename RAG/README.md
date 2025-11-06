# RAG Application for Dell Pro Max GB10

A fully containerized Retrieval Augmented Generation (RAG) application using Open WebUI and Ollama with a 70B parameter language model.

## System Requirements

- **OS**: Linux (Ubuntu 22.04+ recommended)
- **GPU**: NVIDIA GPU with 48GB+ VRAM (for 70B model)
- **RAM**: 16GB+ system RAM
- **Storage**: 100GB+ free disk space
- **Docker**: 20.10+
- **NVIDIA Container Toolkit**: Latest version

## Quick Start

1. **Make the build script executable:**
   ```bash
   git clone https://github.com/cjstoddard/GB10.git
   cd GB10/RAG
   chmod +x build.sh
   ```

2. **Run the build script:**
   ```bash
   ./build.sh
   ```

3. **Access the application:**
   - Open your browser to: `http://localhost:8080` or `http://gb10-ip-address:8080`
   - No authentication required (can be enabled in docker-compose.yaml)

## Architecture

The application consists of two main services:

### Ollama Service
- Runs the LLM models (llama3.1:70b by default)
- Provides the embedding model for RAG (nomic-embed-text)
- Exposes API on port 11434

### Open WebUI
- Web-based chat interface
- RAG document processing
- File upload and management
- Web search integration
- Exposes UI on port 8080

## RAG Features

- **Document Upload**: Upload PDF, TXT, DOC, DOCX, and other document formats
- **Semantic Search**: Uses embeddings for intelligent document retrieval
- **Web Search**: Optional web search integration for real-time information
- **Context Window**: Configurable chunk size and overlap for optimal retrieval
- **Multi-document**: Support for multiple documents in knowledge base

## Configuration

### Changing the Model

Edit `docker-compose.yaml` or pull a different model after setup:

```bash
# List available models
docker exec ollama ollama list

# Pull a different 70B model
docker exec ollama ollama pull llama2:70b

# Use smaller models if needed (less VRAM)
docker exec ollama ollama pull llama3.1:8b
```

### Adjusting RAG Parameters

Edit the environment variables in `docker-compose.yaml`:

- `RAG_EMBEDDING_MODEL`: Embedding model for document vectorization
- `CHUNK_SIZE`: Size of text chunks (default: 1500 characters)
- `CHUNK_OVERLAP`: Overlap between chunks (default: 100 characters)
- `RAG_TOP_K`: Number of relevant chunks to retrieve (default: 5)

### Enable Authentication

In `docker-compose.yaml`, change:
```yaml
- WEBUI_AUTH=false
```
to:
```yaml
- WEBUI_AUTH=true
```

Then restart:
```bash
docker compose restart open-webui
```

## Usage

### Using RAG with Documents

1. Click the **"+"** button in Open WebUI
2. Select **"Upload Files"**
3. Choose your documents (PDF, TXT, etc.)
4. Wait for processing to complete
5. In your chat, reference the documents or ask questions about them

### Model Selection

- Click the model dropdown at the top of the chat
- Select `llama3.1:70b` (or your preferred model)
- Start chatting!

### Web Search

- Enable web search in settings if you want real-time information
- The RAG system will combine document knowledge with web results

## Management Commands

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker logs -f ollama
docker logs -f open-webui
```

### Stop Services
```bash
docker compose down
```

### Restart Services
```bash
docker compose restart
```

### Check Status
```bash
docker compose ps
```

### Backup Data
```bash
# Backup volumes
docker run --rm -v rag_ollama_data:/data -v $(pwd):/backup \
  ubuntu tar czf /backup/ollama_backup.tar.gz /data

docker run --rm -v rag_open_webui_data:/data -v $(pwd):/backup \
  ubuntu tar czf /backup/webui_backup.tar.gz /data
```

### Update Images
```bash
docker compose pull
docker compose up -d
```

## Troubleshooting

### GPU Not Detected
```bash
# Test NVIDIA Docker
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi

# Install nvidia-container-toolkit if needed
# https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html
```

### Out of Memory Errors

If the 70B model is too large for your GPU:

1. Use a quantized version:
   ```bash
   docker exec ollama ollama pull llama3.1:70b-q4_0
   ```

2. Or use a smaller model:
   ```bash
   docker exec ollama ollama pull llama3.1:13b
   ```

### Slow Response Times

- First query is always slower (model loading)
- Subsequent queries should be faster
- Consider using a smaller model for faster responses
- Check GPU utilization: `nvidia-smi`

### Port Already in Use

If ports 8080 or 11434 are taken, edit `docker-compose.yaml`:

```yaml
ports:
  - "8081:8080"  # Change 8080 to 8081 (or any free port)
```

## Performance Optimization

### For 70B Models
- Ensure 48GB+ VRAM available
- Use quantized models (q4_0, q5_0) for less VRAM
- Close other GPU applications

### For Better RAG Results
- Adjust `CHUNK_SIZE` based on document type
- Increase `RAG_TOP_K` for more context (may slow down)
- Use domain-specific embedding models if available

## Security Considerations

- Default setup has authentication disabled
- Enable `WEBUI_AUTH=true` for production
- Consider running behind a reverse proxy (nginx, traefik)
- Use HTTPS in production environments
- Restrict network access with firewall rules

## Additional Models

### Recommended 70B Models
- `llama3.1:70b` - Latest Llama 3.1 (default)
- `llama2:70b` - Llama 2
- `mixtral:8x7b` - Mixture of Experts (good quality, less VRAM)

### Alternative Embedding Models
- `nomic-embed-text` - Default, good general purpose
- `mxbai-embed-large` - Better for technical documents
- `all-minilm` - Faster but less accurate

## Support

For issues:
- Check logs: `docker compose logs`
- Verify GPU access: `docker exec ollama nvidia-smi`
- Ensure enough disk space: `df -h`
- Review Ollama docs: https://ollama.ai/
- Review Open WebUI docs: https://docs.openwebui.com/

## License

This configuration uses:
- Ollama: MIT License
- Open WebUI: MIT License
- Model licenses vary by model (check model cards)
