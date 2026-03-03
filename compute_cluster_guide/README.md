
## Useful Commands

`nvidia-smi`: check GPU status and running processes

`docker ps [-a]`: List containers. Use `-a` to include stopped containers

`docker exec -it CONTAINER_NAME bash`: creates an interactive bash shell section so you can execute commands, etc within the specific docker container

`docker logs CONTAINER_NAME`: view docker logs with respect to that specific container

### Screen Commands

Screens let you run processes in the background, so that you can kill the terminal session but still have the process run in the background.

TO CREATE A SCREEN
`screen -S SCREEN_NAME`

TO ATTACH
`screen -x SCREEN_NAME`

TO DELETE
`screen -S SCREEN_NAME -X quit`

## SSH Setup

### Step 1 — Generate a key (if you don’t already have one)

Check first:

`ls ~/.ssh`

If you already have something like id_ed25519 and id_ed25519.pub, you’re fine.

If not:

`ssh-keygen -t ed25519 -C “your_email@example.com”`

Press Enter through defaults unless you want a custom filename.

This creates:

`~/.ssh/id_ed25519`       (private key)
`~/.ssh/id_ed25519.pub`   (public key)

### Step 2 — Copy your public key to dgx0

`ssh-copy-id USERNAME@dgx0.chapman.edu`

That appends your public key to:
`~/.ssh/authorized_keys`
on the cluster.

After this, you should be able to:

`ssh USERNAME@dgx0.chapman.edu`

without typing your password (unless your key has a passphrase).

### Step 3 (OPTIONAL) — Create SSH alias

Edit your SSH config:

`vim ~/.ssh/config` (or really any text editor, etc)

Add:

```
Host dgx_cluster
    HostName dgx0.chapman.edu
    User USERNAME
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

Save and exit.

Now just try:

`ssh dgx_cluster`

## Docker Container Setup

The cluster requires containerized development in order to run code and manipulate files. This is straightforward through Docker.

SSH into the cluster, and create a project subdir.

From there, create a `Dockerfile`

```dockerfile
FROM ollama/ollama:latest

# command that the container executes 
CMD ["ollama", "serve"]
```

Then we need to build the Docker image:

`docker build -t CONTAINER_NAME .`

Then pull the latest version of the Ollama image:

`docker pull ollama/ollama:latest`

Then we can run the container by using the following `docker run` on the command line.

Note that this specific command will use the first GPU (device=0), expose port 10000, bind the `~/ollama-models:/root/.ollama` as a volume, and use the official `ollama/ollama` docker image.

```
docker run -d \
    --gpus '"device=0"' \
    -p 10000:11434 \
    -v ~/ollama-models:/root/.ollama \
    --name CONTAINER_NAME \
    --restart unless-stopped \
    ollama/ollama
```

## Running a Large Language Model

### Downloading the Model

First we want to download the model.

Run to get an interactive bash shell within the specified container:

`docker exec -it CONTAINER_NAME bash`

Within the specified container, run:

`ollama pull qwen3.5:9b` (or really any LLM you want)

Let the download finish, and then exit the container.

You can try out a quick curl command to make sure it's downloaded correctly:

`curl http://localhost:10000/api/tags`

### SSH Port Forwarding

On another terminal, run this:

`ssh -N -L 10000:localhost:10000 USERNAME@dgx0.chapman.edu`

This is required on both compute clusters do to security around exposing ports.

### Testing out the LLM

I used this quick smoke test script with an accompanying `.env` file:

```python
import os
from dotenv import load_dotenv
from ollama import Client

load_dotenv()

OLLAMA_PORT = os.environ.get("OLLAMA_PORT")
CLUSTER_HOST = os.environ.get("CLUSTER_HOST")
MODEL = os.environ.get("LLM_MODEL")

client = Client(host=f"http://{CLUSTER_HOST}:{OLLAMA_PORT}")

print(f"Chat with model: {MODEL} via Ollama at {CLUSTER_HOST}:{OLLAMA_PORT}")
print('Enter "exit" to quit.\n')

while True:
    user_input = input("You: ")

    if user_input.strip().lower() == "exit":
        break

    response = client.chat(
        model=MODEL,
        messages=[{"role": "user", "content": user_input}],
        stream=True
    )

    print("Assistant: ", end="", flush=True)

    for chunk in response:
        print(chunk["message"]["content"], end="", flush=True)

    print("\n")
```

with this .env file:

```
OLLAMA_PORT=10000
CONTAINER_NAME=CONTAINER_NAME

OLLAMA_MODELS_DIR=./ollama_models
LLM_MODEL=qwen3.5:9b

CLUSTER_HOST=localhost
CLUSTER_USER=USERNAME
#REMOTE_PROJECT_DIR=/home/USERNAME/PROJECT_NAME
```