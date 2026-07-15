{
  fetchFromGitHub,
  python3Packages,
  enable-terok-checks,
  nftables,
  podman,
}:

python3Packages.buildPythonPackage rec {
  pname = "terok-executor";
  version = "v0.3.0";

  src = fetchFromGitHub {
    owner = "terok-ai";
    repo = "terok-executor";
    rev = version;
    sha256 = "sha256-EBcE+OWHjA2xEOo7iQwL22M8b0/3B6kWfR0sjeMFwrI=";
  };

  propagatedBuildInputs = with python3Packages; [
    agent-client-protocol
    prompt-toolkit
    rich
    pyyaml
    pydantic
    ruamel-yaml
    terok-sandbox
    tomli-w
    poetry-core
    poetry-dynamic-versioning
  ];

  patches = [ ./terok-executor-version.patch ];

  pyproject = true;
  build-system = [ python3Packages.setuptools ];

  nativeCheckInputs = with python3Packages; [
    pytest
    pytest-asyncio
    nftables
    podman
  ];

  doCheck = enable-terok-checks;
  installCheckPhase = ''
    runHook preInstallCheck
    export PYTHONPATH="${src}:$PYTHONPATH"
    pytest tests/ -v
    runHook postInstallCheck
  '';

  # Nix is a bit eager in patching shell interpreter locations.
  # Undo the patch for the in-container scripts (such as opencode).
  # There is no Nix inside the containers, hence no patching needed.
  postFixup = ''
    find \
      "$out/${python3Packages.python.sitePackages}/terok_executor/resources/scripts" \
      -type f -print0 |
    while IFS= read -r -d "" file; do
      sed -i 's|#!${python3Packages.python}/bin/python3|#!/usr/bin/env python3|' "$file"
    done
  '';
}
