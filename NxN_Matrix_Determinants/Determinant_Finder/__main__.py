
import argparse
from pathlib import Path

from Determinant_Finder import run_script

input_parser = argparse.ArgumentParser(description='Evaluate matrices in file to calculate the determinants')
input_parser.add_argument('input_file', type=str, help='Starting File Pathname')
input_parser.add_argument('output_file', type=str, help='Output File Pathname')

user_args = input_parser.parse_args()

if Path(user_args.input_file).exists():
    input_path = Path(user_args.input_file)

else:
    raise Exception('Error: Specified input path does not exist')

if Path(user_args.output_file).exists():
    output_path = Path(user_args.output_file)

#  If parent directories exist but not the specific file, creates file
elif Path(user_args.output_file).parent.exists():
    output_path = Path(user_args.output_file)
    Path.touch(output_path, exist_ok=False)

#  Creates file directories and the file if they don't already exist
else:
    output_path = Path(user_args.output_file)
    Path.mkdir(output_path.parent, parents=True, exist_ok=False)
    Path.touch(output_path, exist_ok=False)

run_script(input_path, output_path)
