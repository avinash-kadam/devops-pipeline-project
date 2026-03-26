from flask import Flask, jsonify, request
import os
import socket

app = Flask(__name__)

# Just a sample in-memory store — no DB needed for this demo
tasks = [
    {"id": 1, "title": "Set up CI/CD pipeline", "done": False},
    {"id": 2, "title": "Dockerize the application", "done": True},
    {"id": 3, "title": "Deploy to Kubernetes", "done": False},
]


@app.route("/")
def index():
    return jsonify({
        "message": "DevOps Pipeline Demo App",
        "hostname": socket.gethostname(),
        "version": os.getenv("APP_VERSION", "1.0.0"),
        "environment": os.getenv("APP_ENV", "development"),
    })


@app.route("/health")
def health():
    # Kubernetes liveness/readiness probe hits this endpoint
    return jsonify({"status": "healthy"}), 200


@app.route("/tasks", methods=["GET"])
def get_tasks():
    return jsonify({"tasks": tasks, "total": len(tasks)})


@app.route("/tasks/<int:task_id>", methods=["GET"])
def get_task(task_id):
    task = next((t for t in tasks if t["id"] == task_id), None)
    if not task:
        return jsonify({"error": "Task not found"}), 404
    return jsonify(task)


@app.route("/tasks", methods=["POST"])
def create_task():
    data = request.get_json()
    if not data or "title" not in data:
        return jsonify({"error": "Title is required"}), 400

    new_task = {
        "id": max(t["id"] for t in tasks) + 1,
        "title": data["title"],
        "done": False,
    }
    tasks.append(new_task)
    return jsonify(new_task), 201


if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    debug = os.getenv("APP_ENV", "development") == "development"
    app.run(host="0.0.0.0", port=port, debug=debug)
