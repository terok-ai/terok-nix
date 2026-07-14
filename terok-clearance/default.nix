{
  fetchFromGitHub,
  python3Packages,
  enable-terok-checks,
}:

python3Packages.buildPythonPackage rec {
  pname = "terok-clearance";
  version = "v0.7.3";

  src = fetchFromGitHub {
    owner = "terok-ai";
    repo = "terok-clearance";
    rev = version;
    sha256 = "sha256-KWCDPhF8iDBOYnXM7bYro1/IxYe5P8fHiIPpj0rJwww=";
  };

  patches = [ ./terok-clearance-asyncvarlink.patch ];

  buildInputs = with python3Packages; [
    terok-util
  ];

  propagatedBuildInputs = with python3Packages; [
    asyncvarlink
    dbus-fast
    pyyaml
    poetry-core
    poetry-dynamic-versioning
    terok-util
  ];

  pyproject = true;
  build-system = [ python3Packages.setuptools ];

  nativeCheckInputs = with python3Packages; [
    pytest
    pytest-asyncio
    pydantic
    python-dbusmock
    ruamel-yaml
  ];

  doCheck = enable-terok-checks;
  installCheckPhase = ''
    runHook preInstallCheck
    export PYTHONPATH="${src}:$PYTHONPATH"
    pytest tests/ -v --ignore=tests/integration
    runHook postInstallCheck
  '';

  pythonRuntimeDepsCheckHook = null;
}
