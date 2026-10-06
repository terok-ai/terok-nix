{
  lib,
  old-dbus-fast,
  fetchFromGitHub,
}:

old-dbus-fast.overrideAttrs (
  prev: final: rec {
    version = "v5.2.0";
    src = fetchFromGitHub {
      owner = "Bluetooth-Devices";
      repo = "dbus-fast";
      rev = version;
      sha256 = "sha256-Evm8YTTcVIcMNknJ7GMNVgE8kHd+PO747OqSlHIFK9k=";
    };

    postPatch = ''
      substituteInPlace pyproject.toml \
        --replace-fail "Cython>=3,<3.4" Cython
    '';

    meta = with lib; {
      description = "A faster version of dbus-next";
      homepage = "https://github.com/Bluetooth-Devices/dbus-fast";
      license = licenses.mit;
    };
  }
)
