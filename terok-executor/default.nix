{
  lib,
  fetchFromGitHub,
  python3Packages,
  enable-terok-checks,
  nftables,
  podman,
  git,
}:

python3Packages.buildPythonPackage rec {
  pname = "terok-executor";
  version = "v0.5.0";

  src = fetchFromGitHub {
    owner = "terok-ai";
    repo = "terok-executor";
    rev = version;
    sha256 = "sha256-umtrjwIEG9a8peAXjC3gmEXQHdoQEA5FY01XmbGWmpA=";
  };

  propagatedBuildInputs = with python3Packages; [
    agent-client-protocol
    jinja2
    prompt-toolkit
    rich
    pyyaml
    pydantic
    requests
    ruamel-yaml
    terok-sandbox
    terok-util
    tomli-w
  ];

  patches = [ ./terok-executor-version.patch ];

  pyproject = true;
  build-system = with python3Packages; [
    hatchling
    hatch-vcs
  ];

  nativeCheckInputs = with python3Packages; [
    pytest
    pytest-asyncio
    nftables
    podman
    git
  ];

  doCheck = enable-terok-checks;
  installCheckPhase = ''
    runHook preInstallCheck
    export PYTHONPATH="${src}:$PYTHONPATH"
    TMPDIR=/tmp pytest tests/unit -v
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

  meta = with lib; {
    description = "AI agent repository and instrumentation for running agents in a terok-sandbox environment";
    homepage = "https://github.com/terok-ai/terok-executor";
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
