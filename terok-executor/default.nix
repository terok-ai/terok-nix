{
  lib,
  fetchFromGitHub,
  python3Packages,
  enable-terok-checks,
  writeShellScriptBin,
  nftables,
  podman,
  git,
}:

let
  pname = "terok-executor";
  version = "v0.5.0";

  src = fetchFromGitHub {
    owner = "terok-ai";
    repo = "terok-executor";
    rev = version;
    sha256 = "sha256-umtrjwIEG9a8peAXjC3gmEXQHdoQEA5FY01XmbGWmpA=";
  };

  test-python-env = python3Packages.python.withPackages (
    p: with p; [
      pytest
      pytest-asyncio
      terok-executor
      terok-sandbox
      terok-util
      ruamel-yaml
    ]
  );

  integration-tests = writeShellScriptBin "run" ''
    set -eo pipefail

    unset TMPDIR
    dir="$(mktemp -d)"
    trap "rm -r $dir; echo 'removed test dir'" EXIT

    cp -a ${src}/. "$dir"
    cd "$dir"
    chmod -R a+w ./

    export PYTHONPATH="$dir/src:''${PYTHONPATH:-}"
    export PATH="${git}/bin:${nftables}/bin:$PATH"
    # The podman-backed integration suite is not run by installCheckPhase (it
    # only exercises tests/unit), so without this it would never execute in CI.
    # podman is taken from the host (CI installs it) rather than from this
    # environment: the Nix podman cannot map multiple subordinate IDs without
    # newuidmap, which turns its skip guards into build errors. Install the
    # global shield hooks the launcher path requires so the container nodes run
    # instead of skipping on the hooks_missing guard.
    ${test-python-env}/bin/python -m terok_shield.cli setup
    ${test-python-env}/bin/python \
      -m pytest tests/integration \
      -v
  '';

  pkg = python3Packages.buildPythonPackage {
    inherit pname version src;

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

    passthru = { inherit integration-tests; };

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
  };

in
pkg
