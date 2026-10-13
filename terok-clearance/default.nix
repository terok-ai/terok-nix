{
  lib,
  fetchFromGitHub,
  python3Packages,
  enable-terok-checks,
  writeShellScriptBin,
}:

let
  pname = "terok-clearance";
  version = "v0.8.1";

  src = fetchFromGitHub {
    owner = "terok-ai";
    repo = "terok-clearance";
    rev = version;
    sha256 = "sha256-0sC5wmj0bULDHt8N58N/XBfgV/4LyW/O9UF796205W8=";
  };

  test-python-env = python3Packages.python.withPackages (
    p: with p; [
      pytest
      pytest-asyncio
      pydantic
      python-dbusmock
      ruamel-yaml
      asyncvarlink
      dbus-fast
      pyyaml
      terok-util
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
    ${test-python-env}/bin/python \
      -m pytest tests/integration \
      -v
  '';

  pkg = python3Packages.buildPythonPackage {
    inherit pname version src;

    patches = [ ./terok-clearance-build.patch ];

    buildInputs = with python3Packages; [
      terok-util
    ];

    propagatedBuildInputs = with python3Packages; [
      asyncvarlink
      dbus-fast
      pyyaml
      terok-util
    ];

    pyproject = true;
    build-system = with python3Packages; [
      hatchling
      hatch-vcs
    ];

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
      TMPDIR=/tmp pytest tests/ -v --ignore=tests/integration
      runHook postInstallCheck
    '';

    pythonRuntimeDepsCheckHook = null;
    passthru = { inherit integration-tests; };

    meta = with lib; {
      description = "Firewall UI and notifications for terok-shield";
      homepage = "https://github.com/terok-ai/terok-clearance";
      license = licenses.asl20;
    };
  };

in
pkg
