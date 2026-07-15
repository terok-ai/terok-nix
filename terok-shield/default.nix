{
  fetchFromGitHub,
  python3Packages,
  nftables,
  enable-terok-checks,
}:

python3Packages.buildPythonPackage rec {
  pname = "terok-shield";
  version = "v0.7.2";

  src = fetchFromGitHub {
    owner = "terok-ai";
    repo = "terok-shield";
    rev = version;
    sha256 = "sha256-Fs7gyIVdD55q/hp64XL5yB++6LZsRmj3qj/gJi8+3/I=";
  };

  patches = [ ./terok-shield-pydantic.patch ];

  buildInputs = with python3Packages; [
    terok-util
  ];

  propagatedBuildInputs = with python3Packages; [
    pydantic
    pyyaml
    poetry-core
    poetry-dynamic-versioning
  ];

  pyproject = true;
  build-system = [ python3Packages.setuptools ];

  nativeCheckInputs = with python3Packages; [
    pytest
    pytest-asyncio
    ruamel-yaml
    nftables
  ];

  doCheck = enable-terok-checks;
  installCheckPhase = ''
    runHook preInstallCheck
    export PYTHONPATH="${src}:$PYTHONPATH"
    pytest tests/ -v --ignore=tests/integration/dns
    runHook postInstallCheck
  '';
}
