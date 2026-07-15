{
  fetchFromGitHub,
  python3Packages,
  enable-terok-checks,
  git,
  coreutils,
  nftables,
}:

python3Packages.buildPythonPackage rec {
  pname = "terok-sandbox";
  version = "v0.4.0";

  src = fetchFromGitHub {
    owner = "terok-ai";
    repo = "terok-sandbox";
    rev = version;
    sha256 = "sha256-a3SnkqM34wT7ZwDzrby8rK+JvTcQkD3W/KHh6BCYe2g=";
  };

  patches = [ ./terok-sandbox-version.patch ];

  propagatedBuildInputs = with python3Packages; [
    aiohttp
    cryptography
    jinja2
    keyring
    packaging
    platformdirs
    prompt-toolkit
    pydantic
    ruamel-yaml
    sqlcipher3
    terok-shield
    terok-clearance
    terok-util
    pyyaml
  ];

  pyproject = true;
  build-system = [ python3Packages.setuptools ];

  nativeCheckInputs = with python3Packages; [
    pytest
    pytest-asyncio
    git
    coreutils
    nftables
  ];

  doCheck = enable-terok-checks;

  installCheckPhase = ''
    runHook preInstallCheck
    export PYTHONPATH="${src}:$PYTHONPATH"
    for tool in sleep false echo; do
      grep -Rl "/bin/$tool" tests/ |
        while read file; do
          sed -i "s|/bin/$tool|${coreutils}/bin/$tool|g" "$file"
        done
    done
    pytest tests/ -v
    runHook postInstallCheck
  '';
}
