# Logo generation

This flow uses the python scripts from Leo Moser.

The logo is created as a svg and then exported to a png file for the image and a
filled outline version for the no fill region definition.

## Dependencies

Klayout needs to be installed.

Additionally python packages are needed.
Install the dependencies in a virtual environment.
```sh
python3 -m venv .venv
source .venv/bin/activate
pip3 install -r requirements.txt
```

## Usage

To build the gds files based on the input pngs:
```sh
make
```
The combined output file is `gds/logo.gds`.

To remove the generated files you can use `make clean`.
