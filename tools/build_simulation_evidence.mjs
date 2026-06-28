import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const repositoryRoot = path.resolve(
  path.dirname(new URL(import.meta.url).pathname.replace(/^\/(.:)/, "$1")),
  "..",
);
const testRuns = path.join(repositoryRoot, "simulation", "test_runs");
const baselineCsvPath = path.join(testRuns, "MotionSafetyBench_Simulation_Run01.csv");
const modularCsvPath = path.join(testRuns, "MotionSafetyBench_Modular_FAT_Run02.csv");
const modularJsonPath = path.join(testRuns, "MotionSafetyBench_Modular_FAT_Run02.json");
const outputDir = path.join(repositoryRoot, "outputs", "motion-safety-bench");
const workbookPath = path.join(outputDir, "MotionSafetyBench_Simulation_Evidence.xlsx");
const summaryPreviewPath = path.join(outputDir, "MotionSafetyBench_Summary.png");
const baselinePreviewPath = path.join(testRuns, "MotionSafetyBench_Simulation_Run01.png");
const modularPreviewPath = path.join(testRuns, "MotionSafetyBench_Modular_FAT_Run02.png");

function parseCsvLine(line) {
  const values = [];
  let value = "";
  let quoted = false;
  for (let index = 0; index < line.length; index += 1) {
    const character = line[index];
    if (character === '"') {
      if (quoted && line[index + 1] === '"') {
        value += '"';
        index += 1;
      } else {
        quoted = !quoted;
      }
    } else if (character === "," && !quoted) {
      values.push(value);
      value = "";
    } else {
      value += character;
    }
  }
  values.push(value);
  return values;
}

const baselineText = await fs.readFile(baselineCsvPath, "utf8");
const baselineRows = baselineText
  .split(/\r?\n/)
  .filter((line) => /^\d+\t-?\d+(?:[.,]\d+)?\t\d+\t-?\d+(?:[.,]\d+)?$/.test(line))
  .map((line) => {
    const [positionTime, position, velocityTime, velocity] = line.split("\t");
    return {
      timeMs: Number(positionTime),
      position: Number(position.replace(",", ".")),
      velocityTimeMs: Number(velocityTime),
      velocity: Number(velocity.replace(",", ".")),
    };
  });

const modularText = await fs.readFile(modularCsvPath, "utf8");
const modularLines = modularText.trim().split(/\r?\n/);
const modularHeaders = parseCsvLine(modularLines[0]).map((value) =>
  value.replace(/^\uFEFF/, ""),
);
const modularRows = modularLines.slice(1).map((line) => {
  const fields = parseCsvLine(line);
  const row = Object.fromEntries(modularHeaders.map((header, index) => [header, fields[index]]));
  return {
    elapsedSeconds: Number(row.ElapsedSeconds),
    timestampUtc: row.TimestampUtc,
    running: row.bSimulationRunning === "True",
    complete: row.bSimulationComplete === "True",
    passed: row.bSimulationPassed === "True",
    currentTest: Number(row.nCurrentTest),
    testsRun: Number(row.nTestsRun),
    testsPassed: Number(row.nTestsPassed),
    testsFailed: Number(row.nTestsFailed),
    position: Number(row.fActualPosition),
    velocity: Number(row.fActualVelocity),
    mode: Number(row.eCurrentMode),
    axisState: Number(row.eAxis1State),
    commandStatus: Number(row.eLastCommandStatus),
    simulationMode: row.bSimulationModeActive === "True",
    inMotion: row.bAxis1InMotion === "True",
    axisError: row.bAxis1Error === "True",
    axisErrorCode: Number(row.nAxis1ErrorCode),
    activeAlarmCount: Number(row.nActiveAlarmCount),
    primaryAlarmId: Number(row.nPrimaryAlarmID),
    safetyStatusWord: Number(row.nSafetyStatusWord),
  };
});

const modularSummary = JSON.parse(
  (await fs.readFile(modularJsonPath, "utf8")).replace(/^\uFEFF/, ""),
);
const modularRunDate = modularSummary.generatedUtc
  ? modularSummary.generatedUtc.slice(0, 10)
  : "2026-06-27";
const modularTestCount = modularSummary.tests.length;
const testsLastRow = modularTestCount + 1;
const summarySplit = Math.ceil(modularTestCount / 2);
const summaryPairLastRow = 5 + summarySplit;
const detailedEvidenceComplete = modularSummary.tests.every((test) =>
  test.startedUtc
  && test.completedUtc
  && test.stateTransitions
  && test.alarmsObserved
  && test.recovery
  && test.motionMetrics,
);
if (
  baselineRows.length === 0
  || modularRows.length === 0
  || modularTestCount !== 16
  || !modularSummary.restartValidationPassed
  || !detailedEvidenceComplete
) {
  throw new Error("Evidence inputs are incomplete or not the accepted 16-test suite");
}

function formatTransitions(transitions = []) {
  return transitions
    .map((entry) => `${entry.from}->${entry.to} @ ${Number(entry.elapsedSeconds).toFixed(3)}s`)
    .join(" | ");
}

function formatRestartSnapshot(snapshot) {
  if (!snapshot) return "Not captured";
  return [
    `ADS=${snapshot.adsState}`,
    `tests=${snapshot.testsPassed}/${snapshot.testsRun}`,
    `mode=${snapshot.mode}`,
    `axis=${snapshot.axisState}`,
    `motion=${snapshot.inMotion}`,
    `alarms=${snapshot.activeAlarmCount}`,
    `position=${Number(snapshot.position).toFixed(3)} mm`,
    `velocity=${Number(snapshot.velocity).toFixed(3)} mm/s`,
  ].join("; ");
}

const activeIndexes = baselineRows
  .map((row, index) => ({ row, index }))
  .filter(({ row }) => row.velocity !== 0 || row.position !== 215)
  .map(({ index }) => index);
const activeStart = Math.max(0, Math.min(...activeIndexes) - 50);
const activeEnd = Math.min(baselineRows.length - 1, Math.max(...activeIndexes) + 50);
const activeRows = baselineRows.slice(activeStart, activeEnd + 1);
const activeT0 = activeRows[0].timeMs;

await fs.mkdir(outputDir, { recursive: true });

const workbook = Workbook.create();
const summary = workbook.worksheets.add("Summary");
const tests = workbook.worksheets.add("Modular Test Results");
const detail = workbook.worksheets.add("Test Evidence Detail");
const restarts = workbook.worksheets.add("Restart Validation");
const modular = workbook.worksheets.add("Modular FAT Timeline");
const baseline = workbook.worksheets.add("Baseline Motion Window");
const raw = workbook.worksheets.add("Baseline Raw Data");

for (const sheet of [summary, tests, detail, restarts, modular, baseline, raw]) {
  sheet.showGridLines = false;
}

const dark = "#101923";
const darker = "#0B1118";
const panel = "#152230";
const panelDark = "#111B25";
const cyan = "#27C2D1";
const amber = "#FFBE55";
const green = "#3DDC97";
const red = "#FF6B6B";
const light = "#EAF1F5";
const muted = "#8FA1B3";
const border = "#2B3B4D";

summary.getRange("A1:J2").merge();
summary.getRange("A1").values = [["Industrial Motion & Safety Bench - Validation Evidence"]];
summary.getRange("A1:J2").format = {
  fill: dark,
  font: { bold: true, color: light, size: 18 },
  verticalAlignment: "center",
  horizontalAlignment: "left",
};
summary.getRange("A3:J3").merge();
summary.getRange("A3").values = [[
  `Modular FAT Run 02 - XAE build 4024.75 - ADS port 852 - warm/cold restart verified - ${modularRunDate}`,
]];
summary.getRange("A3:J3").format = { fill: darker, font: { color: muted, size: 10 } };

summary.getRange("A5:B5").values = [["MODULAR RUNTIME GATE", "VALUE"]];
summary.getRange("A6:A12").values = [
  ["Native compile"],
  ["ADS runtime state"],
  ["Tests run"],
  ["Tests passed"],
  ["Tests failed"],
  ["FAT duration (s)"],
  ["Warm/cold restart validation"],
];
summary.getRange("B6:B12").values = [
  ["PASS"],
  [modularSummary.adsState],
  [null],
  [null],
  [null],
  [modularSummary.elapsedSeconds],
  [modularSummary.restartValidationPassed ? "PASS" : "FAIL"],
];
summary.getRange("B8").formulas = [[`=COUNTA('Modular Test Results'!$A$2:$A$${testsLastRow})`]];
summary.getRange("B9").formulas = [[`=COUNTIF('Modular Test Results'!$D$2:$D$${testsLastRow},"PASS")`]];
summary.getRange("B10").formulas = [[`=COUNTIF('Modular Test Results'!$D$2:$D$${testsLastRow},"<>PASS")`]];
summary.getRange("A5:B12").format.borders = { preset: "outside", style: "thin", color: border };
summary.getRange("A5:B5").format = { fill: cyan, font: { bold: true, color: darker } };
summary.getRange("A6:A12").format = { fill: panel, font: { color: light } };
summary.getRange("B6:B12").format = {
  fill: panelDark,
  font: { bold: true, color: light },
  horizontalAlignment: "right",
};
summary.getRange("B6:B7").format = { fill: "#143526", font: { bold: true, color: green } };
summary.getRange("B12").format = { fill: "#143526", font: { bold: true, color: green } };
summary.getRange("B8:B10").format.numberFormat = "0";
summary.getRange("B11").format.numberFormat = "0.000";

summary.getRange("D5:J5").values = [[
  "TEST", "SCENARIO", "RESULT", "TEST", "SCENARIO", "RESULT", "DURATION (ms)",
]];
summary.getRange(`D6:J${summaryPairLastRow}`).values = modularSummary.tests
  .slice(0, summarySplit)
  .map((test, index) => {
  const paired = modularSummary.tests[index + summarySplit];
  return [
    `TR${String(test.testId).padStart(2, "0")}`,
    test.name.replace(/^TR\d+\s+/, ""),
    test.result,
    paired ? `TR${String(paired.testId).padStart(2, "0")}` : "",
    paired ? paired.name.replace(/^TR\d+\s+/, "") : "",
    paired ? paired.result : "",
    paired ? paired.durationMs : "",
  ];
});
summary.getRange("D5:J5").format = { fill: amber, font: { bold: true, color: darker } };
summary.getRange(`D6:J${summaryPairLastRow}`).format = { fill: panelDark, font: { color: light } };
summary.getRange(`F6:F${summaryPairLastRow}`).format = {
  fill: "#143526",
  font: { bold: true, color: green },
  horizontalAlignment: "center",
};
summary.getRange(`I6:I${summaryPairLastRow}`).format = {
  fill: "#143526",
  font: { bold: true, color: green },
  horizontalAlignment: "center",
};
summary.getRange(`J6:J${summaryPairLastRow}`).format.numberFormat = "0";
summary.getRange(`D5:J${summaryPairLastRow}`).format.borders = { preset: "outside", style: "thin", color: border };

summary.getRange("A14:J15").merge();
summary.getRange("A14").values = [[
  `ACCEPTED: the generated modular TwinCAT application compiled, downloaded, ran ${modularSummary.testsPassed}/${modularSummary.testsRun} FAT scenarios with zero failures, passed ADS Stop/Run warm-restart validation, and passed ADS Reset/Run cold-restart validation. Hardware SAT and certified safety validation remain Phase 2 gates.`,
]];
summary.getRange("A14:J15").format = {
  fill: "#143526",
  font: { bold: true, color: green },
  wrapText: true,
  verticalAlignment: "center",
};

summary.getRange("A17:B17").values = [["RECOVERY BASELINE RUN 01", "VALUE"]];
summary.getRange("A18:A22").values = [
  ["Samples"],
  ["Position range (mm)"],
  ["Velocity range (mm/s)"],
  ["Moving samples"],
  ["Evidence role"],
];
summary.getRange("B18").formulas = [["=COUNTA('Baseline Raw Data'!$A$2:$A$25446)"]];
summary.getRange("B19").formulas = [[
  "=MIN('Baseline Raw Data'!$B$2:$B$25446)&\" to \"&MAX('Baseline Raw Data'!$B$2:$B$25446)",
]];
summary.getRange("B20").formulas = [[
  "=MIN('Baseline Raw Data'!$C$2:$C$25446)&\" to \"&MAX('Baseline Raw Data'!$C$2:$C$25446)",
]];
summary.getRange("B21").formulas = [["=COUNTIF('Baseline Raw Data'!$C$2:$C$25446,\"<>0\")"]];
summary.getRange("B22").values = [["Platform-recovery baseline"]];
summary.getRange("A17:B22").format.borders = { preset: "outside", style: "thin", color: border };
summary.getRange("A17:B17").format = { fill: cyan, font: { bold: true, color: darker } };
summary.getRange("A18:A22").format = { fill: panel, font: { color: light } };
summary.getRange("B18:B22").format = { fill: panelDark, font: { color: light } };

summary.getRange("D17:J22").merge();
summary.getRange("D17").values = [[
  "Evidence chain: Run 01 proves the recovered Windows/TwinCAT runtime, ADS and Scope acquisition. Run 02 is the acceptance record for the generated modular architecture. SHA-256 hashes are recorded beside the source evidence. Neither run is a hardware SAT.",
]];
summary.getRange("D17:J22").format = {
  fill: darker,
  font: { color: muted, italic: true },
  wrapText: true,
  verticalAlignment: "center",
};
summary.freezePanes.freezeRows(3);

tests.getRange("A1:F1").values = [[
  "Test ID", "Scenario", "Expected", "Result", "Actual", "Duration (ms)",
]];
tests.getRange(`A2:F${testsLastRow}`).values = modularSummary.tests.map((test) => [
  `TR${String(test.testId).padStart(2, "0")}`,
  test.name,
  test.expected,
  test.result,
  test.actual,
  test.durationMs,
]);
tests.getRange("A1:F1").format = { fill: dark, font: { bold: true, color: light } };
tests.getRange(`A2:F${testsLastRow}`).format = { fill: "#F7FAFC", font: { color: "#1C2935" } };
tests.getRange(`C2:C${testsLastRow}`).format.wrapText = true;
tests.getRange(`E2:E${testsLastRow}`).format.wrapText = true;
tests.getRange(`D2:D${testsLastRow}`).conditionalFormats.add("containsText", {
  text: "PASS",
  format: { fill: "#D9F7E8", font: { bold: true, color: "#11663C" } },
});
tests.getRange(`D2:D${testsLastRow}`).conditionalFormats.add("containsText", {
  text: "FAIL",
  format: { fill: "#FFE0E0", font: { bold: true, color: "#9B1C1C" } },
});
tests.getRange(`F2:F${testsLastRow}`).format.numberFormat = "0";
tests.freezePanes.freezeRows(1);
const testsTable = tests.tables.add(`A1:F${testsLastRow}`, true, "ModularTestResultsTable");
testsTable.style = "TableStyleMedium2";

detail.getRange("A1:T1").values = [[
  "Test ID", "Started UTC", "Completed UTC", "Result", "Mode transitions",
  "Axis 1 transitions", "Command transitions", "Alarm IDs", "Max alarms",
  "Alarms clear at end", "Recovery observed", "Final mode", "Final axis state",
  "Start position (mm)", "End position (mm)", "Minimum position (mm)",
  "Maximum position (mm)", "Travel distance (mm)", "Peak |velocity| (mm/s)", "Samples",
]];
detail.getRange(`A2:T${testsLastRow}`).values = modularSummary.tests.map((test) => [
  `TR${String(test.testId).padStart(2, "0")}`,
  test.startedUtc,
  test.completedUtc,
  test.result,
  formatTransitions(test.stateTransitions.mode),
  formatTransitions(test.stateTransitions.axis1),
  formatTransitions(test.stateTransitions.command),
  test.alarmsObserved.ids.join(", ") || "None",
  test.alarmsObserved.maxActiveCount,
  test.alarmsObserved.clearedAtEnd,
  test.recovery.observed,
  test.recovery.finalMode,
  test.recovery.finalAxisState,
  test.motionMetrics.startPosition,
  test.motionMetrics.endPosition,
  test.motionMetrics.minimumPosition,
  test.motionMetrics.maximumPosition,
  test.motionMetrics.travelDistance,
  test.motionMetrics.peakAbsoluteVelocity,
  test.sampleCount,
]);
detail.getRange("A1:T1").format = { fill: dark, font: { bold: true, color: light } };
detail.getRange(`A2:T${testsLastRow}`).format = { fill: "#F7FAFC", font: { color: "#1C2935" } };
detail.getRange(`D2:D${testsLastRow}`).conditionalFormats.add("containsText", {
  text: "PASS",
  format: { fill: "#D9F7E8", font: { bold: true, color: "#11663C" } },
});
detail.getRange(`E2:G${testsLastRow}`).format.wrapText = true;
detail.getRange(`I2:I${testsLastRow}`).format.numberFormat = "0";
detail.getRange(`N2:S${testsLastRow}`).format.numberFormat = "0.000";
detail.getRange(`T2:T${testsLastRow}`).format.numberFormat = "0";
detail.freezePanes.freezeRows(1);
const detailTable = detail.tables.add(`A1:T${testsLastRow}`, true, "TestEvidenceDetailTable");
detailTable.style = "TableStyleMedium2";

restarts.getRange("A1:I1").values = [[
  "Type", "Control sequence", "Requested UTC", "Observed states", "Result",
  "Acceptance criterion", "Before", "After", "Error",
]];
restarts.getRange("A2:I3").values = modularSummary.restartValidation.map((restart) => [
  restart.type.toUpperCase(),
  restart.controlSequence,
  restart.requestedUtc,
  [restart.stoppedState || restart.resetState, restart.resumedState].filter(Boolean).join(" -> "),
  restart.passed ? "PASS" : "FAIL",
  restart.acceptance,
  formatRestartSnapshot(restart.before),
  formatRestartSnapshot(restart.after),
  restart.error || "",
]);
restarts.getRange("A1:I1").format = { fill: dark, font: { bold: true, color: light } };
restarts.getRange("A2:I3").format = { fill: "#F7FAFC", font: { color: "#1C2935" } };
restarts.getRange("E2:E3").conditionalFormats.add("containsText", {
  text: "PASS",
  format: { fill: "#D9F7E8", font: { bold: true, color: "#11663C" } },
});
restarts.getRange("F2:I3").format.wrapText = true;
restarts.freezePanes.freezeRows(1);
const restartTable = restarts.tables.add("A1:I3", true, "RestartValidationTable");
restartTable.style = "TableStyleMedium2";

modular.getRange("A1:N1").values = [[
  "Elapsed (s)", "Timestamp UTC", "Current test", "Mode", "Axis 1 state",
  "Command status", "Position (mm)", "Velocity (mm/s)", "In motion", "Axis error",
  "Active alarms", "Primary alarm ID", "Safety status word", "Passed",
]];
modular.getRange(`A2:N${modularRows.length + 1}`).values = modularRows.map((row) => [
  row.elapsedSeconds,
  row.timestampUtc,
  row.currentTest,
  row.mode,
  row.axisState,
  row.commandStatus,
  row.position,
  row.velocity,
  row.inMotion,
  row.axisError,
  row.activeAlarmCount,
  row.primaryAlarmId,
  row.safetyStatusWord,
  row.testsPassed,
]);
modular.getRange("A1:N1").format = { fill: dark, font: { bold: true, color: light } };
modular.getRange(`A2:N${modularRows.length + 1}`).format = {
  fill: "#F7FAFC",
  font: { color: "#1C2935" },
};
modular.getRange(`A2:A${modularRows.length + 1}`).format.numberFormat = "0.000";
modular.getRange(`C2:F${modularRows.length + 1}`).format.numberFormat = "0";
modular.getRange(`G2:H${modularRows.length + 1}`).format.numberFormat = "0.000";
modular.getRange(`K2:N${modularRows.length + 1}`).format.numberFormat = "0";
modular.freezePanes.freezeRows(1);
modular.getRange("P1:R1").values = [["Elapsed (s)", "Position (mm)", "Velocity (mm/s)"]];
modular.getRange("P2:R2").formulas = [["=A2", "=G2", "=H2"]];
modular.getRange(`P2:R${modularRows.length + 1}`).fillDown();
const modularChart = modular.charts.add("line", modular.getRange(`P1:R${modularRows.length + 1}`));
modularChart.title = "Modular FAT Run 02 - position and velocity";
modularChart.hasLegend = true;
modularChart.xAxis = { axisType: "textAxis", textStyle: { fontSize: 9 }, tickLabelInterval: 4 };
modularChart.yAxis = { numberFormatCode: "0", min: -10, max: 320 };
modularChart.setPosition("P2", "Y24");

baseline.getRange("A1:C1").values = [[
  "Time from window start (s)", "Position (mm)", "Velocity (mm/s)",
]];
baseline.getRange(`A2:C${activeRows.length + 1}`).values = activeRows.map((row) => [
  (row.timeMs - activeT0) / 1000,
  row.position,
  row.velocity,
]);
baseline.getRange("A1:C1").format = { fill: dark, font: { bold: true, color: light } };
baseline.getRange(`A2:C${activeRows.length + 1}`).format.numberFormat = "0.00";
baseline.freezePanes.freezeRows(1);
const baselineTable = baseline.tables.add(
  `A1:C${activeRows.length + 1}`,
  true,
  "BaselineMotionWindowTable",
);
baselineTable.style = "TableStyleMedium2";
const baselineChart = baseline.charts.add(
  "line",
  baseline.getRange(`A1:C${activeRows.length + 1}`),
);
baselineChart.title = "Recovery baseline Run 01 — active motion window";
baselineChart.hasLegend = true;
baselineChart.xAxis = { axisType: "textAxis", textStyle: { fontSize: 9 }, tickLabelInterval: 20 };
baselineChart.yAxis = { numberFormatCode: "0", min: -10, max: 250 };
baselineChart.setPosition("E2", "N24");

raw.getRange("A1:C1").values = [["Time (ms)", "Position (mm)", "Velocity (mm/s)"]];
raw.getRange(`A2:C${baselineRows.length + 1}`).values = baselineRows.map((row) => [
  row.timeMs,
  row.position,
  row.velocity,
]);
raw.getRange("A1:C1").format = { fill: dark, font: { bold: true, color: light } };
raw.getRange(`A2:C${baselineRows.length + 1}`).format.numberFormat = "0.00";
raw.freezePanes.freezeRows(1);

summary.getRange("A1:J22").format.rowHeight = 22;
summary.getRange("A1:J2").format.rowHeight = 30;
summary.getRange("A14:J15").format.rowHeight = 32;
summary.getRange("A17:J22").format.rowHeight = 24;
summary.getRange("A:A").format.columnWidth = 25;
summary.getRange("B:B").format.columnWidth = 23;
summary.getRange("C:C").format.columnWidth = 3;
summary.getRange("D:D").format.columnWidth = 10;
summary.getRange("E:E").format.columnWidth = 25;
summary.getRange("F:F").format.columnWidth = 10;
summary.getRange("G:G").format.columnWidth = 10;
summary.getRange("H:H").format.columnWidth = 25;
summary.getRange("I:I").format.columnWidth = 10;
summary.getRange("J:J").format.columnWidth = 15;
tests.getRange("A:A").format.columnWidth = 10;
tests.getRange(`A2:A${testsLastRow}`).format.horizontalAlignment = "left";
tests.getRange("B:B").format.columnWidth = 28;
tests.getRange("C:C").format.columnWidth = 42;
tests.getRange("D:D").format.columnWidth = 12;
tests.getRange("E:E").format.columnWidth = 38;
tests.getRange("F:F").format.columnWidth = 16;
tests.getRange(`A1:F${testsLastRow}`).format.rowHeight = 24;
tests.getRange(`C2:C${testsLastRow}`).format.rowHeight = 36;
detail.getRange("A:A").format.columnWidth = 10;
detail.getRange("B:C").format.columnWidth = 26;
detail.getRange("D:D").format.columnWidth = 12;
detail.getRange("E:G").format.columnWidth = 42;
detail.getRange("H:M").format.columnWidth = 18;
detail.getRange("N:T").format.columnWidth = 20;
detail.getRange(`A1:T${testsLastRow}`).format.rowHeight = 30;
detail.getRange(`E2:G${testsLastRow}`).format.rowHeight = 54;
restarts.getRange("A:E").format.columnWidth = 20;
restarts.getRange("F:F").format.columnWidth = 36;
restarts.getRange("G:I").format.columnWidth = 48;
restarts.getRange("A1:I3").format.rowHeight = 42;
modular.getRange("A:N").format.columnWidth = 18;
modular.getRange("B:B").format.columnWidth = 27;
modular.getRange("P:R").format.columnWidth = 18;
baseline.getRange("A:C").format.columnWidth = 24;
raw.getRange("A:C").format.columnWidth = 18;

const summaryPreview = await workbook.render({
  sheetName: "Summary",
  range: "A1:J22",
  scale: 1.3,
  format: "png",
});
await fs.writeFile(summaryPreviewPath, new Uint8Array(await summaryPreview.arrayBuffer()));
const modularPreview = await workbook.render({
  sheetName: "Modular FAT Timeline",
  range: "A1:Y24",
  scale: 1.1,
  format: "png",
});
await fs.writeFile(modularPreviewPath, new Uint8Array(await modularPreview.arrayBuffer()));
const baselinePreview = await workbook.render({
  sheetName: "Baseline Motion Window",
  range: "A1:N24",
  scale: 1.15,
  format: "png",
});
await fs.writeFile(baselinePreviewPath, new Uint8Array(await baselinePreview.arrayBuffer()));

for (const renderCheck of [
  { sheetName: "Modular Test Results", range: `A1:F${testsLastRow}` },
  { sheetName: "Test Evidence Detail", range: `A1:T${testsLastRow}` },
  { sheetName: "Restart Validation", range: "A1:I3" },
  { sheetName: "Baseline Raw Data", range: "A1:C30" },
]) {
  await workbook.render({ ...renderCheck, scale: 1, format: "png" });
}

const evidenceInspection = await workbook.inspect({
  kind: "table",
  sheetId: "Test Evidence Detail",
  range: `A1:T${testsLastRow}`,
  include: "values,formulas",
  tableMaxRows: 18,
  tableMaxCols: 20,
  maxChars: 8000,
});
if (!evidenceInspection.ndjson.includes("TR16")) {
  throw new Error("Detailed workbook evidence did not include all 16 tests");
}

const formulaErrors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
  options: { useRegex: true, maxResults: 300 },
  summary: "final formula error scan",
});
if (!formulaErrors.ndjson.includes("matched 0 entries")) {
  throw new Error(`Workbook formula errors detected: ${formulaErrors.ndjson}`);
}

const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(workbookPath);

console.log(JSON.stringify({
  workbookPath,
  summaryPreviewPath,
  modularPreviewPath,
  baselinePreviewPath,
  baselineSamples: baselineRows.length,
  modularSamples: modularRows.length,
  modularTests: modularSummary.tests.length,
}));
