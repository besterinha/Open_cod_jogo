{ pkgs }: {
  deps = [
    pkgs.git
    pkgs.python3
    pkgs.unzip
    pkgs.xorg.xorgserver # Xvfb — modo visual do self-test
    pkgs.xorg.libXcursor
    pkgs.xorg.libXinerama
    pkgs.xorg.libXrandr
    pkgs.xorg.libXi
    pkgs.libxkbcommon
    pkgs.mesa # llvmpipe — renderização por software
    pkgs.libglvnd
  ];
}
