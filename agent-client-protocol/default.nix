{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonPackage rec {
  pname = "agent-client-protocol";
  version = "0.12.1";

  src = fetchFromGitHub {
    owner = "agentclientprotocol";
    repo = "python-sdk";
    rev = version;
    sha256 = "sha256-GBMzhDHOiXGQDyHtDEBpGL4SH/I16Zh/QMePhiLHJSE=";
  };

  propagatedBuildInputs = [
    python3Packages.pydantic
  ];

  pyproject = true;
  build-system = [
    python3Packages.pdm-backend
    python3Packages.setuptools
  ];

  doCheck = false;

  meta = with lib; {
    description = "Python SDK for ACP clients and agents";
    homepage = "https://github.com/agentclientprotocol/python-sdk";
    license = licenses.asl20;
  };
}
