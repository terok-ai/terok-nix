{
  lib,
  fetchFromGitHub,
  python3Packages,
  enable-terok-checks,
}:

python3Packages.buildPythonPackage rec {
  pname = "mkdocs-terok";
  version = "v0.8.2";

  src = fetchFromGitHub {
    owner = "terok-ai";
    repo = "mkdocs-terok";
    rev = version;
    sha256 = "sha256-bA7y70xxyhG6n3yESRMaW2L/yxW67H4mm6o3mexkxfQ=";
  };

  patches = [ ./mkdocs-terok-version.patch ];

  propagatedBuildInputs = with python3Packages; [
    properdocs
    pyyaml
    squarify
  ];

  pyproject = true;
  build-system = with python3Packages; [
    hatch-vcs
    hatchling
  ];

  nativeCheckInputs = with python3Packages; [
    pytest
    pydantic
  ];

  doCheck = enable-terok-checks;
  installCheckPhase = ''
    runHook preInstallCheck
    export PYTHONPATH="${src}:$PYTHONPATH"
    TMPDIR=/tmp pytest tests/ -v
    runHook postInstallCheck
  '';

  meta = with lib; {
    description = "Importable modules for mkdocs-gen-files";
    homepage = "https://github.com/terok-ai/mkdocs-terok";
    license = licenses.bsd0;
  };
}
