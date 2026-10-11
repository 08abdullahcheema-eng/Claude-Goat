# Linuwu-Sense: patched acer-wmi with PredatorSense features (fans, 4-zone RGB, battery limiter ...)
{ lib, stdenv, kernel, fetchFromGitHub }:
stdenv.mkDerivation {
  pname = "linuwu-sense";
  version = "0-unstable-2026-03-13-${kernel.version}";

  src = fetchFromGitHub {
    owner = "0x7375646F";
    repo = "Linuwu-Sense";
    rev = "73a25ec243a44ba2b1703e8d0a76fa2735062506";
    hash = "sha256-4v+xDrJ+lZIyV/wcRsfMbw933u+yS8uP8TEUVXSpdjA=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;
  hardeningDisable = [ "pic" "format" ];

  buildPhase = ''
    runHook preBuild
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$PWD modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 src/linuwu_sense.ko \
      $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/platform/x86/linuwu_sense.ko
    runHook postInstall
  '';

  meta = {
    description = "Acer Predator/Nitro WMI driver with fan, RGB keyboard and battery controls";
    homepage = "https://github.com/0x7375646F/Linuwu-Sense";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
  };
}
