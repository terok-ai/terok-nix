{
  lib,
  fetchPypi,
  python3Packages,
}:

python3Packages.buildPythonPackage rec {
  pname = "asyncvarlink";
  version = "0.3.2";

  src = fetchPypi {
    pname = "asyncvarlink";
    inherit version;
    sha256 = "sha256-gJBngMxPp4ausF5YWPAjJhR+sU/+dSMXtOZH/FHtKKU=";
  };

  propagatedBuildInputs = [ ];

  pyproject = true;
  build-system = with python3Packages; [
    flit-core
    setuptools
  ];

  doCheck = true;

  meta = with lib; {
    description = "Pure Python type-driven asyncio implementation of varlink";
    homepage = "https://github.com/helmutg/asyncvarlink";
    license = licenses.lgpl2;
  };
}
