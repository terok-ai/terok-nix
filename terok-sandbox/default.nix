{
  lib,
  fetchFromGitHub,
  python3Packages,
  enable-terok-checks,
  writeShellScriptBin,
  git,
  coreutils,
  nftables,
}:

let
  pname = "terok-sandbox";
  version = "v0.6.0";

  src = fetchFromGitHub {
    owner = "terok-ai";
    repo = "terok-sandbox";
    rev = version;
    sha256 = "sha256-XtxJKJggh33yZXncZqcIbKzoSB3MuT0l0bzFUPxswf4=";
  };

  test-python-env = python3Packages.python.withPackages (
    p: with p; [
      pytest
      pytest-asyncio
      terok-sandbox
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
    export PATH="${git}/bin:${coreutils}/bin:${nftables}/bin:$PATH"
    # The live-kernel confinement node is deselected in installCheckPhase because
    # the Nix build sandbox cannot apply the policy reliably; run it here on a
    # real host so the path-isolation proof stays in CI.
    ${test-python-env}/bin/python \
      -m pytest tests/unit/test_supervisor_children.py::TestPolicyConfinesOnTheLiveKernel \
      -v
  '';

  pkg = python3Packages.buildPythonPackage {
    inherit pname version src;

    patches = [ ./terok-sandbox-version.patch ];

    propagatedBuildInputs = with python3Packages; [
      aiohttp
      cryptography
      jinja2
      keyring
      packaging
      platformdirs
      prompt-toolkit
      pydantic
      ruamel-yaml
      sqlcipher3
      terok-shield
      terok-clearance
      terok-util
      pyyaml
    ];

    pyproject = true;
    build-system = with python3Packages; [
      hatchling
      hatch-vcs
    ];

    nativeCheckInputs = with python3Packages; [
      pytest
      pytest-asyncio
      git
      coreutils
      nftables
    ];

    doCheck = enable-terok-checks;

    installCheckPhase = ''
      runHook preInstallCheck
      export PYTHONPATH="${src}:$PYTHONPATH"
      for tool in sleep false echo; do
        while read -r file; do
          sed -i "s|/bin/$tool|${coreutils}/bin/$tool|g" "$file"
        done < <(grep -Rl "/bin/$tool" tests/ || true)
      done
      # Guard the node id: pytest treats an unmatched --deselect as a no-op, so
      # an upstream rename would silently re-enable this sandbox-hostile node
      # and fail the check with a confusing error. Abort early instead.
      node='tests/unit/test_supervisor_children.py::TestPolicyConfinesOnTheLiveKernel::test_gate_accepts_real_git_push_inside_scoped_policy'
      pytest --collect-only -q "$node" >/dev/null \
        || { echo "deselected node not found: $node (upstream renamed it?)" >&2; exit 1; }
      TMPDIR=/tmp pytest tests/ -v --deselect "$node"
      runHook postInstallCheck
    '';

    passthru = { inherit integration-tests; };

    meta = with lib; {
      description = "Hardening for podman containers";
      homepage = "https://github.com/terok-ai/terok-sandbox";
      license = licenses.asl20;
      platforms = platforms.linux;
    };
  };

in
pkg
