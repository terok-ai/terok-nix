{
  fetchFromGitHub,
  python3Packages,
  enable-terok-checks,
}:

python3Packages.buildPythonPackage rec {
  pname = "mkdocs-terok";
  version = "v0.8.0";

  src = fetchFromGitHub {
    owner = "terok-ai";
    repo = "mkdocs-terok";
    rev = version;
    sha256 = "sha256-2UbR8WHiFS2oVElXPYe0Duz0yNtJ5cAMTm0UVAu8LQ0=";
  };

  patches = [ ./mkdocs-terok-version.patch ];

  buildInputs = with python3Packages; [
    hatchling
    hatch-vcs
  ];
  propagatedBuildInputs = with python3Packages; [
    properdocs
    pyyaml
    squarify
  ];

  pyproject = true;
  build-system = [ python3Packages.setuptools ];

  nativeCheckInputs = with python3Packages; [
    pytest
    pydantic
  ];

  doCheck = enable-terok-checks;
  installCheckPhase = ''
    runHook preInstallCheck
    export PYTHONPATH="${src}:$PYTHONPATH"
    pytest tests/ -v
    runHook postInstallCheck
  '';
}
