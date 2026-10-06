{
  lib,
  fetchFromGitHub,
  python3Packages,
  nftables,
  enable-terok-checks,
  writeShellScriptBin,
}:

let
  pname = "terok-shield";
  version = "v0.9.0";

  src = fetchFromGitHub {
    owner = "terok-ai";
    repo = "terok-shield";
    rev = version;
    sha256 = "sha256-GImp3irGKfb66pV2fhKL5gP37REIzn/rQ0dS1uq4MzA=";
  };

  test-python-env = python3Packages.python.withPackages (
    p: with p; [
      pytest
      pytest-asyncio
      ruamel-yaml
      pydantic
      pyyaml
      terok-util
      pkg
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
    export PATH="${nftables}/bin:$PATH"
    # Install the global hooks with the same interpreter the tests run under.
    # The setup receipt and hook JSON bind to sys.executable; under Nix the
    # console-script wrapper reports a different executable than
    # `python -m pytest`, so invoke setup through the module instead.
    ${test-python-env}/bin/python -m terok_shield.cli setup
    # The watch-state confinement node is deselected in installCheckPhase because
    # the Nix build sandbox has no /run; run it here on a real host so the
    # confinement proof stays in CI.
    ${test-python-env}/bin/python \
      -m pytest tests/integration/dns \
      tests/unit/test_confine.py::test_watch_state_lane_excludes_sibling_state_and_system_runtime \
      -v
  '';

  pkg = python3Packages.buildPythonPackage {
    inherit pname version src;

    patches = [ ./terok-shield-pydantic.patch ];

    propagatedBuildInputs = with python3Packages; [
      pydantic
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
      ruamel-yaml
      nftables
    ];

    doCheck = enable-terok-checks;
    installCheckPhase = ''
      runHook preInstallCheck
      export PYTHONPATH="${src}:$PYTHONPATH"
      # A short TMPDIR keeps AF_UNIX socket paths under the kernel's 108 byte
      # limit. The Landlock probe reads /run, which does not exist inside the
      # Nix build sandbox, so it is deselected here and run on a real host by
      # `nix run .#python3Packages.terok-shield.integration-tests` in CI.
      #
      # Guard the node id: pytest treats an unmatched --deselect as a no-op, so
      # an upstream rename would silently re-enable this sandbox-hostile node
      # and fail the check with a confusing error. Abort early instead.
      node='tests/unit/test_confine.py::test_watch_state_lane_excludes_sibling_state_and_system_runtime'
      pytest --collect-only -q "$node" >/dev/null \
        || { echo "deselected node not found: $node (upstream renamed it?)" >&2; exit 1; }
      TMPDIR=/tmp pytest tests/ -v --ignore=tests/integration/dns --deselect "$node"
      runHook postInstallCheck
    '';

    passthru = { inherit integration-tests; };

    meta = with lib; {
      description = "nftables-based egress firewalling for podman containers with domain-based allowlists";
      homepage = "https://github.com/terok-ai/terok-shield";
      license = licenses.asl20;
      platforms = platforms.linux;
    };
  };

in
pkg
