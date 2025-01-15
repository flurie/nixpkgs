{
  lib,
  stdenv,
  buildNpmPackage,
  fetchFromGitHub,
  python3,
  jq,
  deno,
}:
let
  os = if stdenv.hostPlatform.isDarwin then "apple-darwin" else "linux";
  arch = if stdenv.hostPlatform.isAarch64 then "aarch64" else "x86_64";
  platform = "${arch}-${os}";
in
buildNpmPackage rec {
  pname = "single-file-cli";
  version = "2.0.73";

  src = fetchFromGitHub {
    owner = "gildas-lormeau";
    repo = "single-file-cli";
    rev = "v${version}";
    hash = "sha256-fMedP+wp1crHUj9/MVyG8XSsl1PA5bp7/HL4k+X0TRg=";
  };
  npmDepsHash = "sha256-nnOMBb9mHNhDejE3+Kl26jsrTRxSSg500q1iwwVUqP8=";

  nativeBuildInputs = [
    jq
    deno
  ];

  buildPhase = ''
    runHook preBuild

    ./compile.sh

    runHook postBuild
  '';

  postBuild = ''
    patchShebangs ./dist/single-file-${platform}
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp ./dist/single-file-${platform} $out/bin/single-file

    runHook postInstall
  '';

  doCheck = stdenv.hostPlatform.isLinux;
  checkPhase = ''
    runHook preCheck

    ${python3}/bin/python -m http.server --bind 127.0.0.1 &
    pid=$!

    ./single-file \
      --browser-headless \
      --browser-executable-path chromium-browser\
      http://127.0.0.1:8000

    grep -F 'Page saved with SingleFile' 'Directory listing for'*.html

    kill $pid
    wait

    runHook postCheck
  '';

  meta = {
    description = "CLI tool for saving a faithful copy of a complete web page in a single HTML file";
    homepage = "https://github.com/gildas-lormeau/single-file-cli";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ n8henrie ];
    mainProgram = "single-file";
  };
}
