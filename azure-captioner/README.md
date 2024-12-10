# captioner

using astral/uv to manage.
don't use pip.

## how to run

### setup

install dependensies.

```sh
uv sync
```

install envchain

```sh
brew install envchain
```

set SPEECH_KEY and SPEECH_REGION

```sh
envchain --set terfno-azure-speech-test SPEECH_KEY SPEECH_REGION
```

### use specific input on mac

run inputdevicelist command

```sh
./bin/inputdevicelist
```

replace deviceUID

### run

if you need, run venv.

```sh
uv venv # to create .venv
source .venv/bin/activate
```

```sh
envchain terfno-azure-speech-test uv run python ./signage.py
```

## supporting

use ruff to format.

```sh
ruff format
```
