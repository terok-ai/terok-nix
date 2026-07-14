{
  fetchFromGitHub,
  python3Packages,
  enable-terok-checks,
}:

python3Packages.buildPythonPackage rec {
  pname = "terok-util";
  version = "v0.2.1";

  src = fetchFromGitHub {
    owner = "terok-ai";
    repo = "terok-util";
    rev = version;
    sha256 = "sha256-JqoR5cbEVO+z4JkUToC7q3IscDkJop3OIpzFKtaiPzU=";
  };

  patches = [ ./terok-util-version.patch ];

  buildInputs = with python3Packages; [
    platformdirs
  ];

  propagatedBuildInputs = with python3Packages; [
    pydantic
    poetry-core
    poetry-dynamic-versioning
    ruamel-yaml
  ];

  pyproject = true;
  build-system = [ python3Packages.setuptools ];

  nativeCheckInputs = with python3Packages; [
    pytest
    pytest-asyncio
  ];

  doCheck = enable-terok-checks;

  installCheckPhase = ''
    runHook preInstallCheck
    export PYTHONPATH="${src}:$PYTHONPATH"
    pytest tests/ -v
    runHook postInstallCheck
  '';

  pythonRuntimeDepsCheckHook = null;
}
