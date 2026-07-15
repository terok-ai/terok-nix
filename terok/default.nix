{
  fetchFromGitHub,
  python3Packages,
  nftables,
  enable-terok-checks,
}:

python3Packages.buildPythonApplication rec {
  pname = "terok";
  version = "v0.8.4";

  src = fetchFromGitHub {
    owner = "terok-ai";
    repo = "terok";
    rev = version;
    sha256 = "sha256-0KEIsF3QIh/h46L148Gx4XqQfn8VIFKl2Da3qKes4Uw=";
  };

  patches = [ ./terok-version.patch ];

  format = "pyproject";

  propagatedBuildInputs = with python3Packages; [
    argcomplete
    platformdirs
    pydantic
    pyyaml
    requests
    rich
    ruamel-yaml
    terok-clearance
    terok-executor
    terok-sandbox
    terok-shield
    terok-util
    textual
    textual-serve
    unique-namer
    jinja2
    poetry-core
    poetry-dynamic-versioning
  ];

  nativeCheckInputs = with python3Packages; [
    pytest
    pytest-asyncio
    httpx
    mkdocs
    mkdocs-terok
    nftables
    terok-executor
  ];

  doCheck = enable-terok-checks;
  installCheckPhase = ''
    runHook preInstallCheck
    export PYTHONPATH="${src}:$PYTHONPATH"
    export PATH="$out/bin:$PATH"
    # no clue why this is needed,
    # but something in the tests loses the path info
    mkdir -p /usr/bin
    ln -s "${nftables}/bin/nft" /usr/bin/nft
    # TODO try terok build demo for integration tests
    pytest tests/ -v --ignore=tests/integration
    runHook postInstallCheck
  '';
}
