# smoke/ — proofs that the el.N hooks work

## `upscaler-proof/` (el.1, GX3)

`PassthroughUpscaler` — a `ViewportUpscaler` written in Rust (godot-rust 0.5.5, `api-custom-json` against the
Release asset `extension_api.json`). Selected by `SCALING_3D_MODE_CUSTOM`, it bilinearly samples the
internal-resolution colour into `get_upscaled_layer(view)` with a compute pass — the same filter the stock
bilinear mode applies — so a run-scene shot through the hook must match the stock bilinear shot. It also reads
`RenderSceneData.get_taa_jitter()` (P2) and `RenderSceneBuffersRD.get_reset_accumulation()` (P5) every frame.

```sh
curl -sLO https://github.com/WhiteshadowYS/emberloom-godot/releases/download/v4.7.2-el.1/extension_api.json
cd smoke/upscaler-proof && GODOT4_GDEXTENSION_JSON=$PWD/../../extension_api.json cargo build --release
# into a game checkout (never committed there):
mkdir -p <game>/addons/upscaler_proof && cp target/release/libupscaler_proof.so upscaler_proof.gdextension <game>/addons/upscaler_proof/
# build-arena: RSCALE=0.67 UPSCALE=0 tools/screenshot.sh run --at-tick 900               (stock bilinear)
#              RSCALE=0.67 CUSTOM_UPSCALER=PassthroughUpscaler tools/screenshot.sh run --at-tick 900
```

Result of the GX3 run: build-arena block `gx3-engine-patch-set.md` (vault).
