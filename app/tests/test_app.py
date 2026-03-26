import pytest
import json
from app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


def test_index(client):
    res = client.get("/")
    assert res.status_code == 200
    data = json.loads(res.data)
    assert "message" in data
    assert data["message"] == "DevOps Pipeline Demo App"


def test_health_check(client):
    res = client.get("/health")
    assert res.status_code == 200
    data = json.loads(res.data)
    assert data["status"] == "healthy"


def test_get_all_tasks(client):
    res = client.get("/tasks")
    assert res.status_code == 200
    data = json.loads(res.data)
    assert "tasks" in data
    assert isinstance(data["tasks"], list)


def test_get_single_task(client):
    res = client.get("/tasks/1")
    assert res.status_code == 200
    data = json.loads(res.data)
    assert data["id"] == 1


def test_get_missing_task(client):
    res = client.get("/tasks/999")
    assert res.status_code == 404


def test_create_task(client):
    payload = {"title": "New test task"}
    res = client.post("/tasks", data=json.dumps(payload), content_type="application/json")
    assert res.status_code == 201
    data = json.loads(res.data)
    assert data["title"] == "New test task"
    assert data["done"] is False


def test_create_task_missing_title(client):
    res = client.post("/tasks", data=json.dumps({}), content_type="application/json")
    assert res.status_code == 400
