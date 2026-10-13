{
  lib,
  fetchFromGitHub,
  python3Packages,
  enable-terok-checks,
  writeShellScriptBin,
}:

let
  pname = "terok-util";
  version = "v0.4.0";

  src = fetchFromGitHub {
    owner = "terok-ai";
    repo = "terok-util";
    rev = version;
    sha256 = "sha256-rPKxhEu4leUg3MPmgTw1IRBZf6Wxw+0919EhqnLL2HU=";
  };

  test-python-env = python3Packages.python.withPackages (
    p: with p; [
      pytest
      pytest-asyncio
      terok-util
      jinja2
      packaging
      platformdirs
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
    # The filesystem-confinement node is deselected in installCheckPhase because
    # the Nix build sandbox is overlayfs (cross-directory rename fails with
    # EXDEV). Run it here on a real kernel/real host, alongside the integration
    # suite, so the confinement contract is not silently dropped from CI.
    ${test-python-env}/bin/python \
      -m pytest tests/integration \
      tests/unit/test_hardening.py::TestConfineFilesystem::test_confines_reads_and_writes_to_the_lane \
      -v
  '';

  pkg = python3Packages.buildPythonPackage {
    inherit pname version src;

    patches = [ ./terok-util-version.patch ];

    buildInputs = with python3Packages; [
      platformdirs
    ];

    propagatedBuildInputs = with python3Packages; [
      jinja2
      packaging
      platformdirs
      ruamel-yaml
    ];

    pyproject = true;
    build-system = with python3Packages; [
      hatchling
      hatch-vcs
    ];

    nativeCheckInputs = with python3Packages; [
      pytest
      pytest-asyncio
    ];

    doCheck = enable-terok-checks;

    installCheckPhase = ''
      runHook preInstallCheck
      export PYTHONPATH="${src}:$PYTHONPATH"
      # A short TMPDIR keeps AF_UNIX socket paths under the kernel's 108 byte limit.
      # The Landlock cross-directory rename probe fails with EXDEV on the Nix
      # sandbox's overlayfs, so it is deselected here and run on a real kernel by
      # `nix run .#python3Packages.terok-util.integration-tests` in CI.
      #
      # Guard the node id: pytest treats an unmatched --deselect as a no-op, so
      # an upstream rename would silently re-enable this sandbox-hostile node
      # and fail the check with a confusing error. Abort early instead.
      node='tests/unit/test_hardening.py::TestConfineFilesystem::test_confines_reads_and_writes_to_the_lane'
      pytest --collect-only -q "$node" >/dev/null \
        || { echo "deselected node not found: $node (upstream renamed it?)" >&2; exit 1; }
      TMPDIR=/tmp pytest tests/unit -v --deselect "$node"
      runHook postInstallCheck
    '';

    pythonRuntimeDepsCheckHook = null;
    passthru = { inherit integration-tests; };

    meta = with lib; {
      description = "Common utility library for the terok ecosystem packages";
      homepage = "https://github.com/terok-ai/terok-util";
      license = licenses.asl20;
    };
  };

in
pkg
