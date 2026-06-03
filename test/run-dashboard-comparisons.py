#!/usr/bin/env python3
import argparse
import subprocess
from pathlib import Path
from typing import Dict, Iterator, Optional, Tuple


DASHBOARD_EXIT_MESSAGES = {
    0: "no conflicts found",
    1: "error in input files or arguments",
    2: "precision conflicts found",
    3: "only one tool emits a PO for a given range",
    4: "safety conflicts found",
    5: "internal error (unexpected state)",
}

SUCCESSFUL_COMPARISON_EXIT_CODES = {0, 2, 3, 4}


def collect_checks_json(root: Path) -> Dict[Path, Path]:
    """
    Collect all checks.json files under `root`.

    Returns:
        rel_task_dir (relative to root) -> absolute path to checks.json

    Example:
        root/.../2Nested-2.yml/checks.json
        => rel_task_dir = Path("2Nested-2.yml")
    """
    mapping: Dict[Path, Path] = {}
    for checks in root.rglob("checks.json"):
        rel_task_dir = checks.parent.relative_to(root)
        mapping[rel_task_dir] = checks.resolve()
    return mapping


def find_task_pairs(
    mopsa_root: Path,
    goblint_root: Path
) -> Iterator[Tuple[Path, Path, Path]]:
    """
    Yield (rel_task_dir, mopsa_checks_json, goblint_checks_json) for tasks present in both roots.
    """
    mopsa = collect_checks_json(mopsa_root)
    goblint = collect_checks_json(goblint_root)
    common = sorted(set(mopsa.keys()) & set(goblint.keys()))

    for rel in common:
        yield rel, mopsa[rel], goblint[rel]


def output_filename(rel_task_dir: Path) -> str:
    """
    Turn a relative task dir path into a stable filename.
    Example: "foo/2Nested-2.yml" -> "foo__2Nested-2.yml"
    """
    return "__".join(rel_task_dir.parts)


def append_log(log_file: Path, message: str) -> None:
    with log_file.open("a", encoding="utf-8") as log:
        log.write(message)
        if not message.endswith("\n"):
            log.write("\n")


def run_dashboard(
    dashboard_root: Path,
    project_root: Path,
    mopsa_json: Path,
    goblint_json: Path,
    output_file: Path,
    log_file: Optional[Path] = None,
 ) -> int:
    """
    Run:
        dune exec dashboard -- <args>
    """

    cmd = [
        "dune", "exec", "dashboard", "--",
        "--exclude-not-found", "true",
        "--project", str(project_root),
    ]

    overflow_categories = [
        "signed_integer_overflow_in_arithmetic_operator",
        "unsigned_integer_overflow_in_arithmetic_operator",
    ]

    for cat in overflow_categories:
        cmd.extend(["--filter-error-category", cat])

    cmd.extend([
        str(mopsa_json),
        str(goblint_json),
        "--output", str(output_file),
    ])


    if log_file is not None:
        with log_file.open("a", encoding="utf-8") as log:
            log.write(f"[RUN] {' '.join(cmd)} (cwd={dashboard_root})\n")
            log.flush()
            completed = subprocess.run(
                cmd,
                cwd=dashboard_root,
                check=False,
                stdout=log,
                stderr=subprocess.STDOUT,
                text=True,
            )
    else:
        print("[RUN]", " ".join(cmd), f"(cwd={dashboard_root})")
        completed = subprocess.run(cmd, cwd=dashboard_root, check=False)

    return completed.returncode


def main():
    parser = argparse.ArgumentParser(
        description="Batch compare Mopsa/Goblint dashboard results from per-task checks.json."
    )
    parser.add_argument(
        "--mopsa",
        type=Path,
        required=True,
        help="Path to Mopsa results root (contains task dirs with checks.json).",
    )
    parser.add_argument(
        "--goblint",
        type=Path,
        required=True,
        help="Path to Goblint results root (contains task dirs with checks.json).",
    )
    parser.add_argument(
        "--dashboard",
        type=Path,
        default=Path("./open-verification-dashboard"),
        help="Path to the open-verification-dashboard project root (directory containing dune-project).",
    )
    parser.add_argument(
        "--project",
        type=Path,
        required=True,
        help="Path to the benchmark project root used by dashboard for source lookup.",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=Path("dashboard-outputs"),
        help="Directory to write dashboard comparison outputs.",
    )
    parser.add_argument(
        "--log-file",
        type=Path,
        default=Path("dashboard-output.log"),
        help="File to append dashboard stdout/stderr to.",
    )
    parser.add_argument(
        "--progress-every",
        type=int,
        default=100,
        help="Print progress every N completed comparisons. Use 0 to disable.",
    )

    args = parser.parse_args()

    mopsa_root = args.mopsa.resolve()
    goblint_root = args.goblint.resolve()
    dashboard_root = args.dashboard.resolve()
    project_root = args.project.resolve()
    out_dir = args.out.resolve()
    log_file = args.log_file.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    print(f"Scanning Mopsa checks under:   {mopsa_root}")
    print(f"Scanning Goblint checks under: {goblint_root}")
    print(f"Dashboard root:               {dashboard_root}")
    print(f"Project root:                 {project_root}")
    print(f"Outputs go to:                {out_dir}")
    print(f"Dashboard log:                {log_file}")

    task_pairs = list(find_task_pairs(mopsa_root, goblint_root))
    total_tasks = len(task_pairs)
    print(f"Tasks in both roots:          {total_tasks}")

    for idx, (rel_task_dir, mopsa_checks, goblint_checks) in enumerate(task_pairs, start=1):
        out_file = out_dir / f"{output_filename(rel_task_dir)}.comparison.json"
        out_file.parent.mkdir(parents=True, exist_ok=True)

        return_code = run_dashboard(
            dashboard_root=dashboard_root,
            project_root=project_root,
            mopsa_json=mopsa_checks,
            goblint_json=goblint_checks,
            output_file=out_file,
            log_file=log_file,
        )

        status = DASHBOARD_EXIT_MESSAGES.get(return_code, "unknown dashboard exit code")
        if return_code in SUCCESSFUL_COMPARISON_EXIT_CODES:
            append_log(
                log_file,
                f"[INFO] dashboard completed for {rel_task_dir} with return code {return_code}: {status}",
            )
        else:
            append_log(
                log_file,
                f"[ERROR] dashboard execution failed for {rel_task_dir} with return code {return_code}: {status}",
            )

        if args.progress_every > 0 and (idx % args.progress_every == 0 or idx == total_tasks):
            percentage = (idx / total_tasks) * 100 if total_tasks else 100.0
            print(f"[PROGRESS] {idx}/{total_tasks} ({percentage:.1f}%)")


if __name__ == "__main__":
    main()
