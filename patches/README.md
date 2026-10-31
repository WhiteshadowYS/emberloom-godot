# Patch ledger

One row per patch, in apply order. Status: `planned` · `local` · `upstream-open` · `merged-in-<ver>` · `dropped`.
A patch is dropped the day upstream ships its equivalent. Keep this table and the vault plan (§4) in step.

| # | File | Purpose | Files / LOC | Upstream | Status | Last rebase | Notes |
|---|---|---|---|---|---|---|---|
| P1 | `0010-upscaler-hook.patch` | `ViewportUpscaler` resource + `SCALING_3D_MODE_CUSTOM` + `_render_callback(RenderData)` / `get_upscaled_layer` — the hook every vendor upscaler backend plugs into | 22 / +521 −17 | godotengine/godot#114670 (missed the 4.8 freeze, earliest 4.9) | planned (el.1, release 0.4.x) | — | cherry-pick of the upstream PR as-is; drops when #114670 merges |
| P2 | `0020-scene-data-bindings.patch` | bind `RenderSceneData.get_taa_jitter / get_prev_taa_jitter / get_prev_cam_transform / get_prev_cam_projection / get_z_near / get_z_far / get_time_step` | 6 / ~40 | to open | planned (el.1) | — | fields exist in `RenderSceneDataRD`; trivial |
| P3 | `0030-driver-callback.patch` | `RenderingDevice.add_driver_callback(Callable, resources, usages)` → native command buffer for NGX / FFX / XeSS evaluate | ~8 / ~120 | to open | planned (el.1) | — | NVIDIA fork proves the need |
| P4 | `0040-vk-extension-injection.patch` | extra Vulkan (+ D3D12) instance / device extensions from project settings — or 0 LOC via a `VulkanHooks` module | 2 / ~40 (or 0) | to open | planned (el.1) | — | decide module vs patch at el.1 |
| P5 | `0050-opaque-copy-reset.patch` | opaque-only colour copy as `color_opaque` + a real `reset_accumulation` signal (fixes the stock FSR 2.2 hard-coded `false`) | 3 / ~60 | godotengine/godot#13718 (asked for) | planned (el.1, optional) | — | — |
| L1 | `0100-low-latency-vulkan.patch` | `VK_AMD_anti_lag` + `VK_NV_low_latency2`: anti-lag update before input + present, NV markers + sleep + present id | ~4 / ~150 | to open | planned (release prep, T4) | — | RADV support lands with Mesa 26.3 |
| C1 | `0200-*.patch` | cherry-picks of merged upstream fixes (waitable swapchains #106221 if merged; 4.8 mip streaming / contact shadows while on 4.7) | — | the upstream commits | as needed | — | — |

## Build-flag changes (not patches, recorded here too)

| Rev | Change | Why |
|---|---|---|
| el.0 | `production=yes` (LTO full, `optimize=speed`, static libstdc++), `module_openxr_enabled=no`, `module_mobile_vr_enabled=no`, `module_webxr_enabled=no` | the game has no XR; everything else stays until a module audit measures a saving |
