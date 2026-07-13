{
  fetchFromGitHub,
  python3Packages,
}:

python3Packages.buildPythonApplication rec {
  pname = "terok";
  version = "v0.8.4";

  src = fetchFromGitHub {
    owner = "terok-ai";
    repo = "terok";
    rev = version;
    sha256 = "sha256-0KEIsF3QIh/h46L148Gx4XqQfn8VIFKl2Da3qKes4Uw=";
  };

  patches = [ ./terok-version.patch ];

  format = "pyproject";

  propagatedBuildInputs = with python3Packages; [
    argcomplete
    platformdirs
    pydantic
    pyyaml
    requests
    rich
    ruamel-yaml
    terok-clearance
    terok-executor
    terok-sandbox
    terok-shield
    terok-util
    textual
    textual-serve
    unique-namer
    jinja2
    poetry-core
    poetry-dynamic-versioning
  ];

  doCheck = false;
  nativeCheckInputs = with python3Packages; [
    pytest
    pytest-asyncio
    httpx
  ];

  checkPhase = ''
    runHook preCheck
    pytest tests/ -v --ignore=tests/integration --ignore=tests/e2e
    runHook postCheck
  '';
}
