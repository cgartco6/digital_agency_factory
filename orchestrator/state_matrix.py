import json
import threading
from enum import Enum
from pathlib import Path
from typing import Dict, Any, List

class ModuleStatus(str, Enum):
    PENDING = "Pending"
    IN_PROCESS = "In Process"
    VALIDATING = "Validating"
    LOCKED = "Locked"
    FAILED = "Failed"

STATE_FILE = Path(__file__).parent / "build_state.json"
_lock = threading.Lock()

DEFAULT_STATE = {
    "modules": {
        "orchestrator": {"status": ModuleStatus.LOCKED.value, "coverage": 100.0, "tests_passed": 5},
        "studio_branding": {"status": ModuleStatus.PENDING.value, "coverage": 0.0, "tests_passed": 0},
        "studio_design": {"status": ModuleStatus.PENDING.value, "coverage": 0.0, "tests_passed": 0},
        "studio_marketing": {"status": ModuleStatus.PENDING.value, "coverage": 0.0, "tests_passed": 0},
        "core_mesh": {"status": ModuleStatus.PENDING.value, "coverage": 0.0, "tests_passed": 0}
    },
    "logs": [
        "[SYSTEM INIT] Meta-Orchestrator state matrix online."
    ]
}

def get_state() -> Dict[str, Any]:
    with _lock:
        if not STATE_FILE.exists():
            with open(STATE_FILE, "w") as f:
                json.dump(DEFAULT_STATE, f, indent=2)
            return DEFAULT_STATE
        with open(STATE_FILE, "r") as f:
            return json.load(f)

def update_module_status(module_name: str, status: ModuleStatus, coverage: float = 0.0, tests_passed: int = 0):
    with _lock:
        state = get_state()
        if module_name in state["modules"]:
            state["modules"][module_name]["status"] = status.value
            state["modules"][module_name]["coverage"] = coverage
            state["modules"][module_name]["tests_passed"] = tests_passed
        with open(STATE_FILE, "w") as f:
            json.dump(state, f, indent=2)

def append_log(message: str):
    with _lock:
        state = get_state()
        state["logs"].append(message)
        if len(state["logs"]) > 200:
            state["logs"] = state["logs"][-200:]
        with open(STATE_FILE, "w") as f:
            json.dump(state, f, indent=2)
