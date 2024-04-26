"""
INPUT:
- INDIR
  - csv file: write input to this file
  - Structures: copy into this subfolder
"""

import argparse
import json
import shutil
import subprocess
# basic
import tempfile
import textwrap
from pathlib import Path
from typing import Any, Dict

import yaml
from loguru import logger

# ==================== Configuration ====================
REPOBASE = Path(__file__).resolve().parent  # path to DiffDock-PP


# ==================== Function ====================
def write_csv(path: Path, pdbcode: str):
    with open(path, "w") as file:
        file.write(f"path,split\n")
        file.write(f"{pdbcode},test\n")


def process_config(config: Path, input_dir: Path) -> Dict:
    # load config yaml file
    with open(config, "r") as file:
        config = yaml.safe_load(file)

    # change the data_file and data_path fields
    config["data"]["data_file"] = str(input_dir / "splits_test.csv")
    config["data"]["data_path"] = str(input_dir)

    return config


def run_inference(
    inference_sh_script: Path,
    pdbcode: str,
    outdir: Path,
    config_filepath: Path,
) -> dict[str, Any]:
    # run inference code
    cmd_list = [
        "zsh",
        str(inference_sh_script),
        "-n",
        str(pdbcode),
        "-o",
        str(outdir),
        "-c",
        str(config_filepath),
    ]
    process = subprocess.Popen(
        args=cmd_list, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    stdout, stderr = process.communicate()
    stdout = stdout.decode("utf-8")
    stderr = stderr.decode("utf-8")
    retcode = process.wait()
    # log to stdout
    logger.info("Completed running inference code")
    logger.info(f"retcode:\n{retcode}")
    logger.info(f"stdout:\n{stdout}")
    logger.info(f"stderr:\n{stderr}")
    logger.info(f"Output files are in {outdir}")
    # return the info
    return {
        "retcode": retcode,
        "stdout": stdout,
        "stderr": stderr,
    }


def write_config(outdir: Path, processed_config: Dict, filename: str = "config.yaml"):
    with open(str(outdir / filename), "w") as file:
        yaml.dump(processed_config, file)

def save_log_to_json(log_info: Dict[str, str], logfile: Path):
    with open(logfile, "w") as file:
        json.dump(log_info, file, indent=2)


def cli() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawTextHelpFormatter,
        description="Filter out problematic AbM numbered file identifiers.",
        epilog=textwrap.dedent(
            """
        Example usage:
            python run_one_abdb.py -n 1a22 -i 1a22_r_b.pdb -j 1a22_l_b.pdb -o /path/to/output
        """
        ),
    )
    parser.add_argument("-n", "--pdbcode", type=str, required=False, help="PDB code")
    parser.add_argument(
        "-i", "--input_ab", type=Path, help="pdb file path with ab only"
    )
    parser.add_argument(
        "-j", "--input_ag", type=Path, help="pdb file path with ag only"
    )
    parser.add_argument(
        "-s",
        "--inference_code",
        type=Path,
        default=REPOBASE / "src" / "db5_inference.sh",
        help="inference code",
    )
    parser.add_argument(
        "-o", "--outdir", type=Path, default=Path.cwd(), help="output directory"
    )
    parser.add_argument(
        "-c",
        "--config_template",
        type=Path,
        default=REPOBASE / "config" / "single_pair_inference.yaml",
        help="config file",
    )
    parser.add_argument("--save_log", action="store_true",
                        help="Save log to a json file under the output dir with name log.json")
    args = parser.parse_args()

    return args


# ==================== Main ====================


if __name__ == "__main__":
    args = cli()

    # sanity check
    assert args.input_ab.exists(), f"File not found: {args.input_ab}"
    assert args.input_ag.exists(), f"File not found: {args.input_ag}"
    assert args.inference_code.exists(), f"File not found: {args.inference_code}"
    args.outdir.mkdir(parents=True, exist_ok=True)
    if args.pdbcode is None:
        args.pdbcode = args.input_ab.stem

    with tempfile.TemporaryDirectory() as tmpdir:
        D = Path(tmpdir)
        (D / "structures").mkdir(exist_ok=True, parents=True)
        logger.debug(f"Created temporary directory: {D/'structures'}")

        # change the config
        logger.debug(f"Processing config file: {args.config_template}")
        processed_config = process_config(config=args.config_template, input_dir=D)
        logger.debug(f"Processed config: {processed_config}")

        # save to a file
        logger.debug(f"Writing config file to {D/'config.yaml'}")
        write_config(D, processed_config, "config.yaml")
        logger.debug(f"Written config file to {D/'config.yaml'}")

        # write splits file
        logger.debug(f"Writing splits file to {D/'splits_test.csv'}")
        write_csv(D / "splits_test.csv", args.pdbcode)
        logger.debug(f"Written splits file to {D/'splits_test.csv'}")

        # copy structure files
        logger.debug(f"Copying structure files to {D/'structures'}")
        shutil.copy(args.input_ab, D / "structures" / f"{args.pdbcode}_r_b.pdb")
        shutil.copy(args.input_ag, D / "structures" / f"{args.pdbcode}_l_b.pdb")
        logger.debug(f"Copied structure files to {D/'structures'}")

        # run inference
        logger.debug(f"Running inference code: {args.inference_code}")
        ret_info = run_inference(
            inference_sh_script=args.inference_code,
            pdbcode=args.pdbcode,
            outdir=args.outdir,
            config_filepath=D / "config.yaml",
        )
        logger.debug("Completed running inference code with ret_info:\n"
                     f"{json.dumps(ret_info, indent=2)}")
        # save log if needed
        if args.save_log:
            logger.debug(f"Saving log to {args.outdir/'log.json'}")
            save_log_to_json(log_info=ret_info, logfile=args.outdir / "log.json")
            logger.debug(f"Saved log to {args.outdir/'log.json'}")

    logger.debug("Completed running the script, and removed temporary directory.")
