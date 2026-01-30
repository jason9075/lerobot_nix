{
  description = "LeRobot devShell using mkShell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        # 定義所有需要的運行時庫
        runtimeLibs = with pkgs; [
          stdenv.cc.cc.lib
          zlib
          libusb1
          udev
          libGL
          libxkbcommon
          fontconfig
          wayland
          vulkan-loader
          # X11 libs for pynput
          xorg.libX11
          xorg.libXcursor
          xorg.libXrandr
          xorg.libXi
          xorg.libXtst
          xorg.libXinerama
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            python3
            python3Packages.pip
            python3Packages.virtualenv
            git
            pkg-config
          ] ++ runtimeLibs;

          shellHook = ''
            # 建立並啟動虛擬環境
            if [ ! -d ".venv" ]; then
              python -m venv .venv
            fi
            source .venv/bin/activate

            # 自動安裝依賴
            if [ -f "pyproject.toml" ]; then
              pip install -e ".[feetech]"
            fi

            # 重要：在 mkShell 中，你必須手動構造 LD_LIBRARY_PATH
            # 否則 pip 安裝的套件會找不到 .so 檔
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath runtimeLibs}:/run/opengl-driver/lib:$LD_LIBRARY_PATH"
            
            echo "🛡️ LeRobot Shell (mkShell mode) is ready."
          '';
        };
      }
    );
}
