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
    program = "${pkgs.terok.integration-tests}/bin/run";
    meta = {
      description = "Run the terok pytest integration suite";
    };
  };
  terok-clearance-integration-tests = {
    type = "app";
    program = "${pkgs.python3Packages.terok-clearance.integration-tests}/bin/run";
    meta = {
      description = "Run the terok-clearance integration suite";
    };
  };
  terok-shield-integration-tests = {
    type = "app";
    program = "${pkgs.python3Packages.terok-shield.integration-tests}/bin/run";
    meta = {
      description = "Run the terok-shield integration suite";
    };
  };
  terok-util-integration-tests = {
    type = "app";
    program = "${pkgs.python3Packages.terok-util.integration-tests}/bin/run";
    meta = {
      description = "Run the terok-util integration suite and live-kernel confinement node";
    };
  };
  terok-sandbox-integration-tests = {
    type = "app";
    program = "${pkgs.python3Packages.terok-sandbox.integration-tests}/bin/run";
    meta = {
      description = "Run the terok-sandbox vault integration suite and live-kernel confinement node";
    };
  };
  terok-executor-integration-tests = {
    type = "app";
    program = "${pkgs.python3Packages.terok-executor.integration-tests}/bin/run";
    meta = {
      description = "Run the terok-executor podman-backed integration suite";
    };
  };
}
