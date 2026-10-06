{ pkgs }:
{
  default = {
    type = "app";
    program = "${pkgs.terok}/bin/terok";
    meta = {
      description = "Manager for podman containers for AI coding agents";
    };
  };
  terok = {
    type = "app";
    program = "${pkgs.terok}/bin/terok";
    meta = {
      description = "Manager for podman containers for AI coding agents";
    };
  };
  terok-integration-tests = {
    type = "app";
    program = "${pkgs.terok.passthru.integration-tests}/bin/run";
    meta = {
      description = "Run the terok pytest integration suite";
    };
  };
  terok-clearance-integration-tests = {
    type = "app";
    program = "${pkgs.python3Packages.terok-clearance.passthru.integration-tests}/bin/run";
    meta = {
      description = "Run the terok-clearance integration suite";
    };
  };
  terok-shield-integration-tests = {
    type = "app";
    program = "${pkgs.python3Packages.terok-shield.passthru.integration-tests}/bin/run";
    meta = {
      description = "Run the terok-shield integration suite";
    };
  };
  terok-util-integration-tests = {
    type = "app";
    program = "${pkgs.python3Packages.terok-util.passthru.integration-tests}/bin/run";
    meta = {
      description = "Run the terok-util integration suite and live-kernel confinement node";
    };
  };
  terok-sandbox-integration-tests = {
    type = "app";
    program = "${pkgs.python3Packages.terok-sandbox.passthru.integration-tests}/bin/run";
    meta = {
      description = "Run the terok-sandbox live-kernel confinement node";
    };
  };
}
