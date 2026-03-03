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