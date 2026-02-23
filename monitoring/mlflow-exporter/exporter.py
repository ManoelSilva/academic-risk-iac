"""
MLflow Metrics Exporter for Prometheus.

Reads experiment metrics from the MLflow tracking server API and exposes them
as Prometheus gauge metrics, enabling Grafana dashboards over time-series data.
"""

import os
import time
import logging
from mlflow.tracking import MlflowClient
from prometheus_client import start_http_server, Gauge, Info

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

MLFLOW_TRACKING_URI = os.environ.get("MLFLOW_TRACKING_URI", "http://mlflow:5001")
SCRAPE_INTERVAL = int(os.environ.get("SCRAPE_INTERVAL", "30"))
EXPORTER_PORT = int(os.environ.get("EXPORTER_PORT", "8000"))

client = MlflowClient(tracking_uri=MLFLOW_TRACKING_URI)

mlflow_metric = Gauge(
    "mlflow_run_metric",
    "MLflow run metric value",
    ["experiment_name", "run_name", "model_type", "metric_name"],
)

mlflow_param = Info(
    "mlflow_run_params",
    "MLflow run parameters",
    ["experiment_name", "run_name"],
)

mlflow_experiment_run_count = Gauge(
    "mlflow_experiment_run_count",
    "Number of runs per experiment",
    ["experiment_name"],
)

mlflow_best_score = Gauge(
    "mlflow_best_score",
    "Best metric score across all runs in an experiment",
    ["experiment_name", "metric_name"],
)


def collect_metrics():
    """Fetch all experiments and their runs from MLflow, then update Prometheus gauges."""
    try:
        experiments = client.search_experiments()
        logger.info("Found %d experiments", len(experiments))

        for exp in experiments:
            logger.info("Processing experiment: '%s' (id=%s)", exp.name, exp.experiment_id)
            if exp.name == "Default":
                logger.info("Skipping 'Default' experiment (no user runs)")
                continue

            runs = client.search_runs(
                experiment_ids=[exp.experiment_id],
                order_by=["start_time DESC"],
            )

            mlflow_experiment_run_count.labels(experiment_name=exp.name).set(len(runs))

            best_scores: dict[str, float] = {}

            for run in runs:
                run_name = run.info.run_name or run.info.run_id[:8]
                model_type = run.data.params.get("model_type", "unknown")

                safe_params = {
                    k: str(v)
                    for k, v in run.data.params.items()
                    if k in ("model_type", "scoring", "cv_folds", "test_size", "class_weight")
                }
                mlflow_param.labels(
                    experiment_name=exp.name, run_name=run_name
                ).info(safe_params)

                for metric_key, metric_value in run.data.metrics.items():
                    mlflow_metric.labels(
                        experiment_name=exp.name,
                        run_name=run_name,
                        model_type=model_type,
                        metric_name=metric_key,
                    ).set(metric_value)

                    if metric_key not in best_scores or metric_value > best_scores[metric_key]:
                        best_scores[metric_key] = metric_value

            for metric_key, best_val in best_scores.items():
                mlflow_best_score.labels(
                    experiment_name=exp.name, metric_name=metric_key
                ).set(best_val)

    except Exception:
        logger.exception("Error collecting MLflow metrics")


def main():
    logger.info("Starting MLflow Prometheus Exporter on port %d", EXPORTER_PORT)
    logger.info("MLflow tracking URI: %s", MLFLOW_TRACKING_URI)
    logger.info("Scrape interval: %ds", SCRAPE_INTERVAL)

    start_http_server(EXPORTER_PORT)

    while True:
        collect_metrics()
        time.sleep(SCRAPE_INTERVAL)


if __name__ == "__main__":
    main()
