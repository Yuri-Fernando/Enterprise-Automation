/* =============================================================================
 * Enterprise Cloud Automation & Infrastructure Platform — Dashboard app.js
 * jQuery-based renderer for the static demo dashboard.
 *
 * Data source: js/data.example.json (fetched via $.getJSON), shaped after
 * database/schema.sql (`executions`, `incidents`, `inventory`).
 *
 * To plug a real API later: replace DATA_URL below with the API endpoint
 * (e.g. GET /api/dashboard) that returns the same JSON shape. Everything
 * else (rendering) stays the same. See dashboard/README.md.
 * ============================================================================= */

(function ($) {
  "use strict";

  const DATA_URL = "js/data.example.json";

  /** Escape a string for safe HTML interpolation. */
  function esc(value) {
    if (value === null || value === undefined) return "";
    return String(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function formatDateTime(iso) {
    if (!iso) return "—";
    const d = new Date(iso);
    if (isNaN(d.getTime())) return esc(iso);
    return d.toLocaleString("pt-BR", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  }

  function formatDuration(seconds) {
    if (seconds === null || seconds === undefined) return "—";
    if (seconds < 60) return `${seconds}s`;
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m}m ${s}s`;
  }

  function envBadgeClass(env) {
    const e = String(env || "").toLowerCase();
    if (e === "prod") return "env-prod";
    if (e === "staging") return "env-staging";
    return "env-dev";
  }

  function statusPillClass(status) {
    const s = String(status || "").toLowerCase();
    if (["success", "running", "available", "active", "resolved"].includes(s)) {
      return "text-bg-success";
    }
    if (["failed", "stopped", "open"].includes(s)) {
      return "text-bg-danger";
    }
    return "text-bg-secondary";
  }

  /* --------------------------------------------------------------- Cards */

  function renderSummary(data) {
    const executions = data.executions || [];
    const incidents = data.incidents || [];
    const inventory = data.inventory || [];

    const openIncidents = incidents.filter((i) => i.status === "OPEN");
    const resolvedIncidents = incidents.filter((i) => i.status === "RESOLVED");

    const recoveryTimes = resolvedIncidents
      .map((i) => i.recovery_time_seconds)
      .filter((v) => typeof v === "number");
    const mttr =
      recoveryTimes.length > 0
        ? Math.round(recoveryTimes.reduce((a, b) => a + b, 0) / recoveryTimes.length)
        : null;

    $("#stat-total-resources").text(inventory.length);
    $("#stat-open-incidents").text(openIncidents.length);
    $("#stat-resolved-incidents").text(resolvedIncidents.length);
    $("#stat-mttr").text(mttr !== null ? formatDuration(mttr) : "—");

    $("#executions-count").text(`${executions.length} itens`);
    $("#incidents-count").text(`${incidents.length} itens`);

    if (data.generated_at) {
      $("#last-updated").text(`dados gerados em ${formatDateTime(data.generated_at)}`);
    }
  }

  /* ---------------------------------------------------------- Inventory */

  function renderInventory(inventory) {
    const $tbody = $("#inventory-table tbody");
    $tbody.empty();
    $("#inventory-count").text(`${inventory.length} itens`);

    if (!inventory.length) {
      $tbody.append(
        '<tr><td colspan="6" class="text-center text-muted py-4">Nenhum recurso encontrado.</td></tr>'
      );
      return;
    }

    const rows = inventory
      .slice()
      .sort((a, b) => (a.resource_type || "").localeCompare(b.resource_type || ""))
      .map((item) => {
        const env = (item.tags && item.tags.Environment) || "—";
        return `
          <tr>
            <td><span class="text-mono">${esc(item.resource_id)}</span></td>
            <td>${esc(String(item.resource_type || "").toUpperCase())}</td>
            <td>${esc(item.region)}</td>
            <td>
              <span class="status-dot status-${esc(String(item.status || "").toLowerCase())}"></span>
              ${esc(item.status)}
            </td>
            <td><span class="badge env-badge ${envBadgeClass(env)}">${esc(env)}</span></td>
            <td>${formatDateTime(item.last_checked_at)}</td>
          </tr>`;
      })
      .join("");

    $tbody.html(rows);
  }

  /* --------------------------------------------------------- Executions */

  function renderExecutions(executions) {
    const $tbody = $("#executions-table tbody");
    $tbody.empty();
    $("#executions-count").text(`${executions.length} itens`);

    if (!executions.length) {
      $tbody.append(
        '<tr><td colspan="5" class="text-center text-muted py-4">Nenhuma execução encontrada.</td></tr>'
      );
      return;
    }

    const rows = executions
      .slice()
      .sort((a, b) => new Date(b.started_at) - new Date(a.started_at))
      .map((run) => {
        return `
          <tr title="${esc(run.output_summary || "")}">
            <td><span class="text-mono">${esc(run.tool)}</span></td>
            <td>${esc(run.action)}</td>
            <td><span class="badge env-badge ${envBadgeClass(run.environment)}">${esc(run.environment)}</span></td>
            <td><span class="badge ${statusPillClass(run.status)}">${esc(run.status)}</span></td>
            <td>${formatDateTime(run.started_at)}</td>
          </tr>`;
      })
      .join("");

    $tbody.html(rows);
  }

  /* ---------------------------------------------------------- Incidents */

  function renderIncidents(incidents) {
    const $timeline = $("#incidents-timeline");
    $timeline.empty();
    $("#incidents-count").text(`${incidents.length} itens`);

    if (!incidents.length) {
      $timeline.append('<li class="text-center text-muted py-4">Nenhum incidente registrado.</li>');
      return;
    }

    const items = incidents
      .slice()
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
      .map((incident) => {
        const isResolved = incident.status === "RESOLVED";
        const statusClass = isResolved ? "status-resolved" : "status-open";
        const badgeClass = statusPillClass(incident.status);

        const detailLines = [];
        if (incident.root_cause) {
          detailLines.push(`<div class="incident-detail"><strong>Root cause:</strong> ${esc(incident.root_cause)}</div>`);
        }
        if (incident.action) {
          detailLines.push(`<div class="incident-detail"><strong>Ação:</strong> ${esc(incident.action)}</div>`);
        }
        if (incident.validation) {
          detailLines.push(`<div class="incident-detail"><strong>Validação:</strong> ${esc(incident.validation)}</div>`);
        }

        const recovery =
          incident.recovery_time_seconds !== null && incident.recovery_time_seconds !== undefined
            ? `<span class="badge text-bg-light border">Recovery: ${formatDuration(incident.recovery_time_seconds)}</span>`
            : "";

        return `
          <li class="timeline-item ${statusClass}">
            <div class="d-flex flex-wrap align-items-center gap-2 justify-content-between">
              <div class="incident-title">
                ${esc(incident.label)} — ${esc(incident.host)}
                <span class="badge env-badge ${envBadgeClass(incident.environment)} ms-1">${esc(incident.environment)}</span>
              </div>
              <div class="d-flex align-items-center gap-2">
                ${recovery}
                <span class="badge ${badgeClass}">${esc(incident.status)}</span>
              </div>
            </div>
            <div class="incident-meta">${esc(incident.problem)} · aberto em ${formatDateTime(incident.created_at)}</div>
            ${detailLines.join("")}
          </li>`;
      })
      .join("");

    $timeline.html(items);
  }

  /* ------------------------------------------------------------- Charts */

  // Instâncias vivas de Chart.js, guardadas para poder destruir/recriar se
  // renderCharts() rodar de novo (ex.: futura API real com polling).
  let charts = {};

  function destroyCharts() {
    Object.values(charts).forEach((c) => c && c.destroy());
    charts = {};
  }

  function renderIncidentsStatusChart(incidents) {
    const canvas = document.getElementById("chart-incidents-status");
    if (!canvas) return;

    const open = incidents.filter((i) => i.status === "OPEN").length;
    const resolved = incidents.filter((i) => i.status === "RESOLVED").length;
    const other = incidents.length - open - resolved;

    const labels = ["Abertos", "Resolvidos"];
    const values = [open, resolved];
    const colors = ["#c62828", "#1a7f37"];
    if (other > 0) {
      labels.push("Outros");
      values.push(other);
      colors.push("#94a3b8");
    }

    charts.incidentsStatus = new Chart(canvas, {
      type: "doughnut",
      data: {
        labels,
        datasets: [{ data: values, backgroundColor: colors, borderWidth: 0 }],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { position: "bottom" },
        },
      },
    });
  }

  function renderExecutionsByToolChart(executions) {
    const canvas = document.getElementById("chart-executions-by-tool");
    if (!canvas) return;

    const tools = Array.from(new Set(executions.map((e) => e.tool))).sort();
    const successCounts = tools.map(
      (tool) => executions.filter((e) => e.tool === tool && e.status === "success").length
    );
    const failedCounts = tools.map(
      (tool) => executions.filter((e) => e.tool === tool && e.status === "failed").length
    );

    charts.executionsByTool = new Chart(canvas, {
      type: "bar",
      data: {
        labels: tools,
        datasets: [
          { label: "Sucesso", data: successCounts, backgroundColor: "#1a7f37" },
          { label: "Falha", data: failedCounts, backgroundColor: "#c62828" },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          x: { stacked: true },
          y: { stacked: true, beginAtZero: true, ticks: { precision: 0 } },
        },
        plugins: {
          legend: { position: "bottom" },
        },
      },
    });
  }

  function renderCharts(data) {
    // Chart.js vem de CDN (igual jQuery/Bootstrap) — se estiver indisponível
    // (ex.: demo 100% offline), os cards ficam vazios em vez de quebrar o
    // resto do dashboard.
    if (typeof Chart === "undefined") {
      console.warn("[dashboard] Chart.js not loaded, skipping charts");
      return;
    }
    destroyCharts();
    renderIncidentsStatusChart(data.incidents || []);
    renderExecutionsByToolChart(data.executions || []);
  }

  /* --------------------------------------------------------------- Error */

  function renderLoadError(err) {
    $("#last-updated").text("falha ao carregar dados");
    $("#inventory-table tbody").html(
      '<tr><td colspan="6" class="text-center text-danger py-4">Erro ao carregar dados de exemplo.</td></tr>'
    );
    $("#executions-table tbody").html(
      '<tr><td colspan="5" class="text-center text-danger py-4">Erro ao carregar dados de exemplo.</td></tr>'
    );
    $("#incidents-timeline").html(
      '<li class="text-center text-danger py-4">Erro ao carregar dados de exemplo.</li>'
    );
    console.error("[dashboard] failed to load", DATA_URL, err);
  }

  /* ---------------------------------------------------------------- Init */

  function init() {
    $.getJSON(DATA_URL)
      .done(function (data) {
        renderSummary(data);
        renderInventory(data.inventory || []);
        renderExecutions(data.executions || []);
        renderIncidents(data.incidents || []);
        renderCharts(data);
      })
      .fail(function (jqxhr, textStatus, error) {
        renderLoadError(error || textStatus);
      });
  }

  $(function () {
    // Loaded via CDN jQuery in index.html; guard in case it's ever missing
    // (e.g. offline demo without internet) so the page fails loudly instead
    // of silently.
    if (typeof $ !== "function") {
      console.error("[dashboard] jQuery not loaded");
      return;
    }
    init();
  });
})(jQuery);
