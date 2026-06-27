"use strict";

const TESTS = [
  ["TR01", "Power-up and Init", "Safe startup enters INIT"],
  ["TR02", "Homing complete", "Home reference established"],
  ["TR03", "Absolute move", "Move to 100 mm"],
  ["TR04", "Relative move", "Advance by 50 mm"],
  ["TR05", "Manual jog", "Jog and stop on release"],
  ["TR06", "Soft-limit rejection", "Reject target beyond 300 mm"],
  ["TR07", "E-stop during motion", "Stop and enter FAULT"],
  ["TR08", "Fault reset cycle", "FAULT → RESET → INIT"],
  ["TR09", "Alarm acknowledgement", "Acknowledge active alarm"],
  ["TR10", "Trace logging", "Events written to buffer"],
  ["TR11", "Warm restart", "No stale motion command"],
  ["TR12", "Cold-start defaults", "Safe defaults restored"]
];

TESTS.splice(0, TESTS.length,
  ["TR01", "Startup and homing", "Safe startup and home reference"],
  ["TR02", "Absolute move", "Move to 100 mm"],
  ["TR03", "Relative move", "Advance by 50 mm"],
  ["TR04", "Jog positive and negative", "Jog both directions and stop"],
  ["TR05", "Positive limit switch", "Stop, FAULT, recover"],
  ["TR06", "Negative limit switch", "Stop, FAULT, recover"],
  ["TR07", "E-stop during motion", "Stop and enter FAULT"],
  ["TR08", "Guard door during motion", "Inhibit motion and recover"],
  ["TR09", "Drive fault", "Latch drive fault and recover"],
  ["TR10", "Following error", "Detect following error"],
  ["TR11", "Encoder feedback loss", "Detect feedback loss"],
  ["TR12", "EtherCAT dropout", "Detect network dropout"],
  ["TR13", "Warm restart", "No stale motion command"],
  ["TR14", "Cold-start defaults", "Safe defaults restored"],
  ["TR15", "Watchdog timeout", "Detect watchdog timeout"],
  ["TR16", "Invalid command transition", "Reject invalid OFF-state move"]
);

const state = {
  running: false,
  paused: false,
  estop: false,
  mode: "INIT",
  position: 0,
  target: 0,
  velocity: 0,
  homed: false,
  alarm: false,
  testIndex: -1,
  testElapsed: 0,
  lastFrame: Date.now(),
  passed: 0,
  samples: [],
  events: []
};

const el = id => document.getElementById(id);
const testGrid = el("testGrid");
const canvas = el("trendCanvas");
const ctx = canvas.getContext("2d");

TESTS.forEach(([id, name, expected], index) => {
  const item = document.createElement("article");
  item.className = "test-item";
  item.innerHTML = `<header><strong>${id} · ${name}</strong><span id="result-${index}" class="result">NOT RUN</span></header><p>${expected}</p>`;
  testGrid.appendChild(item);
});

function addEvent(source, message) {
  state.events.unshift({ time: new Date(), source, message });
  state.events = state.events.slice(0, 30);
  renderEvents();
}

function renderEvents() {
  el("eventLog").innerHTML = state.events.map(event =>
    `<li><time>${event.time.toLocaleTimeString()}</time><b>${event.source}</b><span>${event.message}</span></li>`
  ).join("");
}

function axisPercent(value) {
  return Math.max(0, Math.min(100, ((value + 10) / 310) * 100));
}

function setResult(index, value) {
  const result = el(`result-${index}`);
  result.textContent = value;
  result.className = `result ${value === "PASS" ? "pass" : value === "RUNNING" ? "running" : ""}`;
}

function completeTest() {
  setResult(state.testIndex, "PASS");
  state.passed += 1;
  el("testScore").textContent = `${state.passed} / ${TESTS.length}`;
  addEvent("TEST", `${TESTS[state.testIndex][0]} passed`);
  state.testIndex += 1;
  state.testElapsed = 0;
  if (state.testIndex >= TESTS.length) {
    state.running = false;
    state.mode = "INIT";
    state.velocity = 0;
    addEvent("TEST", `All ${TESTS.length} simulation scenarios passed`);
  } else {
    setResult(state.testIndex, "RUNNING");
  }
}

function moveToward(target, speed = 200, deltaSeconds = 0.04) {
  state.target = target;
  const delta = target - state.position;
  const step = speed * deltaSeconds;
  if (Math.abs(delta) <= step) {
    state.position = target;
    state.velocity = 0;
    return true;
  }
  state.velocity = Math.sign(delta) * speed;
  state.position += Math.sign(delta) * step;
  return false;
}

function runScenario() {
  if (!state.running || state.paused) return;
  // TR07 deliberately owns the E-stop recovery sequence. A manually latched
  // E-stop still freezes every other scenario until the operator releases it.
  if (state.estop && state.testIndex !== 6) return;
  const now = Date.now();
  const deltaSeconds = Math.min(1, Math.max(0.001, (now - state.lastFrame) / 1000));
  state.lastFrame = now;
  state.testElapsed += deltaSeconds * 1000;

  switch (state.testIndex) {
    case 0:
      state.mode = state.testElapsed < 400 ? "INIT" : "HOMING";
      state.velocity = -50;
      state.position = Math.max(0, state.position - (50 * deltaSeconds));
      if (state.position === 0 && state.testElapsed > 900) {
        state.homed = true;
        state.mode = "MANUAL";
        completeTest();
      }
      break;
    case 1:
      state.mode = "MANUAL";
      if (moveToward(100, 200, deltaSeconds)) completeTest();
      break;
    case 2:
      if (moveToward(150, 200, deltaSeconds)) completeTest();
      break;
    case 3:
      state.target = 200;
      if (state.testElapsed < 800) {
        state.velocity = 50;
        state.position += 50 * deltaSeconds;
      } else if (state.testElapsed < 1600) {
        state.velocity = -50;
        state.position -= 50 * deltaSeconds;
      } else {
        state.velocity = 0;
        completeTest();
      }
      break;
    case 4:
      if (state.testElapsed < 600) moveToward(250, 100, deltaSeconds);
      else if (state.testElapsed < 1300) {
        state.mode = "FAULT";
        state.velocity = 0;
        state.alarm = true;
        if (state.testElapsed < 650) addEvent("SAFETY", "Positive limit switch opened");
      } else {
        state.mode = "MANUAL";
        state.alarm = false;
        completeTest();
      }
      break;
    case 5:
      if (state.testElapsed < 600) moveToward(-5, 100, deltaSeconds);
      else if (state.testElapsed < 1300) {
        state.mode = "FAULT";
        state.velocity = 0;
        state.alarm = true;
        if (state.testElapsed < 650) addEvent("SAFETY", "Negative limit switch opened");
      } else {
        state.mode = "MANUAL";
        state.alarm = false;
        completeTest();
      }
      break;
    case 6:
      state.mode = "MANUAL";
      if (state.testElapsed < 700) moveToward(250, 100, deltaSeconds);
      else if (!state.estop && state.testElapsed < 1600) triggerEstop(true);
      else if (state.testElapsed > 1600) {
        triggerEstop(false);
        state.mode = "MANUAL";
        completeTest();
      }
      break;
    case 7:
      if (state.testElapsed < 600) moveToward(180, 100, deltaSeconds);
      else if (state.testElapsed < 1300) {
        state.mode = "FAULT";
        state.velocity = 0;
        state.alarm = true;
        if (state.testElapsed < 650) addEvent("SAFETY", "Guard door opened during motion");
      } else {
        state.mode = "MANUAL";
        state.alarm = false;
        completeTest();
      }
      break;
    case 8:
      state.alarm = state.testElapsed < 700;
      state.mode = state.alarm ? "FAULT" : "MANUAL";
      state.velocity = 0;
      if (state.testElapsed <= 100) addEvent("AXIS", "Drive fault injected");
      if (state.testElapsed > 1000) completeTest();
      break;
    case 9:
      state.alarm = state.testElapsed < 700;
      state.mode = state.alarm ? "FAULT" : "MANUAL";
      state.velocity = 0;
      if (state.testElapsed <= 100) addEvent("AXIS", "Following error exceeded limit");
      if (state.testElapsed > 1000) completeTest();
      break;
    case 10:
      state.alarm = state.testElapsed < 700;
      state.mode = state.alarm ? "FAULT" : "MANUAL";
      state.velocity = 0;
      if (state.testElapsed <= 100) addEvent("AXIS", "Encoder feedback lost");
      if (state.testElapsed > 1000) completeTest();
      break;
    case 11:
      state.alarm = state.testElapsed < 700;
      state.mode = state.alarm ? "FAULT" : "MANUAL";
      state.velocity = 0;
      if (state.testElapsed <= 100) addEvent("NETWORK", "EtherCAT link dropped");
      if (state.testElapsed > 1000) completeTest();
      break;
    case 12:
      state.mode = "MANUAL";
      state.velocity = 0;
      if (state.testElapsed > 700) completeTest();
      break;
    case 13:
      state.mode = "INIT";
      state.velocity = 0;
      state.alarm = false;
      state.target = state.position;
      if (state.testElapsed > 700) completeTest();
      break;
    case 14:
      state.alarm = state.testElapsed < 700;
      state.mode = state.alarm ? "FAULT" : "MANUAL";
      state.velocity = 0;
      if (state.testElapsed <= 100) addEvent("SYSTEM", "Watchdog timeout injected");
      if (state.testElapsed > 1000) completeTest();
      break;
    case 15:
      state.mode = "OFF";
      state.velocity = 0;
      state.alarm = state.testElapsed < 700;
      if (state.testElapsed <= 100) addEvent("COMMAND", "Move rejected in OFF state");
      if (state.testElapsed > 900) {
        state.alarm = false;
        completeTest();
      }
      break;
  }
}

function triggerEstop(active) {
  state.estop = active;
  state.alarm = active;
  if (active) {
    state.mode = "FAULT";
    state.velocity = 0;
    addEvent("SAFETY", "Emergency-stop chain opened; motion inhibited");
  } else {
    state.mode = "RESET";
    addEvent("SAFETY", "Emergency-stop chain restored");
  }
}

function drawTrend() {
  const w = canvas.width;
  const h = canvas.height;
  ctx.clearRect(0, 0, w, h);
  ctx.fillStyle = "#0c131b";
  ctx.fillRect(0, 0, w, h);
  ctx.strokeStyle = "#223141";
  ctx.lineWidth = 1;
  for (let x = 0; x <= w; x += w / 10) {
    ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, h); ctx.stroke();
  }
  for (let y = 0; y <= h; y += h / 6) {
    ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke();
  }

  const data = state.samples;
  if (data.length < 2) return;
  const path = (key, max, color) => {
    ctx.beginPath();
    data.forEach((sample, index) => {
      const x = (index / (data.length - 1)) * w;
      const y = h - ((sample[key] + (key === "velocity" ? 250 : 10)) / max) * h;
      if (index === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
    });
    ctx.strokeStyle = color;
    ctx.lineWidth = 2.2;
    ctx.stroke();
  };
  path("position", 310, "#27c2d1");
  path("velocity", 500, "#ffbe55");
}

function render() {
  const moving = Math.abs(state.velocity) > 0.01;
  el("clock").textContent = new Date().toLocaleTimeString();
  el("modeValue").textContent = state.mode;
  el("modeDetail").textContent = state.running ? `Executing ${TESTS[state.testIndex]?.[0] ?? "suite"}` : "Ready for simulation";
  el("positionValue").textContent = state.position.toFixed(1);
  el("targetValue").textContent = state.target.toFixed(1);
  el("velocityValue").textContent = state.velocity.toFixed(1);
  el("motionState").textContent = moving ? "Motion active" : "Standstill";
  el("safetyValue").textContent = state.estop ? "TRIPPED" : "HEALTHY";
  el("safetyValue").className = state.estop ? "text-fault" : "text-good";
  el("alarmCount").textContent = `${state.alarm ? 1 : 0} active alarm${state.alarm ? "" : "s"}`;
  el("carriage").style.left = `${axisPercent(state.position)}%`;
  el("targetMarker").style.left = `${axisPercent(Math.min(state.target, 300))}%`;
  el("axisStateBadge").textContent = state.estop ? "ERRORSTOP" : moving ? "MOVING" : "STANDSTILL";
  el("axisStateBadge").className = `badge ${state.estop ? "fault" : moving ? "warning" : "neutral"}`;
  el("estopLamp").className = `lamp ${state.estop ? "fault" : "good"}`;
  el("relayLamp").className = `lamp ${state.estop ? "fault" : "good"}`;
  el("homedLamp").className = `lamp ${state.homed ? "good" : ""}`;
  el("motionLamp").className = `lamp ${moving ? "warning" : ""}`;
  el("faultLamp").className = `lamp ${state.alarm ? "fault" : ""}`;
  el("estopButton").classList.toggle("latched", state.estop);

  state.samples.push({ position: state.position, velocity: state.velocity });
  if (state.samples.length > 300) state.samples.shift();
  drawTrend();
}

el("runButton").addEventListener("click", () => {
  if (!state.running) {
    TESTS.forEach((_, index) => setResult(index, "NOT RUN"));
    state.running = true;
    state.paused = false;
    state.estop = false;
    state.alarm = false;
    state.mode = "INIT";
    state.position = 0;
    state.target = 0;
    state.velocity = 0;
    state.homed = false;
    state.testIndex = 0;
    state.testElapsed = 0;
    state.lastFrame = Date.now();
    state.passed = 0;
    state.samples = [];
    el("testScore").textContent = `0 / ${TESTS.length}`;
    setResult(0, "RUNNING");
    addEvent("TEST", `Automated ${TESTS.length}-scenario simulation started`);
  }
});

el("pauseButton").addEventListener("click", () => {
  state.paused = !state.paused;
  el("pauseButton").textContent = state.paused ? "Resume" : "Pause";
  addEvent("OPERATOR", state.paused ? "Simulation paused" : "Simulation resumed");
});

el("resetButton").addEventListener("click", () => {
  Object.assign(state, { running: false, paused: false, estop: false, mode: "INIT", position: 0, target: 0, velocity: 0, homed: false, alarm: false, testIndex: -1, testElapsed: 0, lastFrame: Date.now(), passed: 0, samples: [] });
  TESTS.forEach((_, index) => setResult(index, "NOT RUN"));
  el("testScore").textContent = `0 / ${TESTS.length}`;
  addEvent("OPERATOR", "Simulation reset to safe defaults");
});

el("estopButton").addEventListener("click", () => triggerEstop(!state.estop));

document.querySelectorAll(".tab").forEach(tab => tab.addEventListener("click", () => {
  document.querySelectorAll(".tab").forEach(item => item.classList.remove("active"));
  document.querySelectorAll(".panel").forEach(panel => panel.classList.remove("active"));
  tab.classList.add("active");
  el(tab.dataset.panel).classList.add("active");
}));

addEvent("SYSTEM", "HMI prototype initialized in simulation mode");
setInterval(() => { runScenario(); render(); }, 40);
