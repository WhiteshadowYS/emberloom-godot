//! el.1 hook proof — `PassthroughUpscaler`, a `ViewportUpscaler` written in Rust.
//!
//! Selected with `Viewport.scaling_3d_mode = SCALING_3D_MODE_CUSTOM` + `scaling_3d_custom_upscaler`, it does
//! what the stock bilinear mode does — sample the internal-resolution colour with a linear sampler at every
//! target pixel centre — but as a compute pass into `RenderSceneBuffersRD.get_upscaled_layer(view)`, i.e. through
//! the custom-upscaler hook (P1). It also reads the P2 / P5 inputs each frame so the bindings are exercised.
use godot::classes::rendering_device::{SamplerFilter, SamplerRepeatMode, ShaderStage, UniformType};
use godot::classes::{
    IViewportUpscaler, RdSamplerState, RdShaderSource, RdUniform, RenderData, RenderSceneBuffersRd,
    RenderingDevice, RenderingServer, UniformSetCacheRd, ViewportUpscaler,
};
use godot::prelude::*;

struct Proof;

#[gdextension]
unsafe impl ExtensionLibrary for Proof {}

const BLIT_GLSL: &str = r#"
#version 450
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;
layout(set = 0, binding = 0) uniform sampler2D src_color;
layout(rgba16f, set = 0, binding = 1) uniform restrict writeonly image2D dst_color;
void main() {
    ivec2 p = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = imageSize(dst_color);
    if (any(greaterThanEqual(p, size))) {
        return;
    }
    vec2 uv = (vec2(p) + 0.5) / vec2(size);
    imageStore(dst_color, p, textureLod(src_color, uv, 0.0));
}
"#;

#[derive(GodotClass)]
#[class(base = ViewportUpscaler, init, tool)]
pub struct PassthroughUpscaler {
    base: Base<ViewportUpscaler>,
    #[init(val = Rid::Invalid)]
    shader: Rid,
    #[init(val = Rid::Invalid)]
    pipeline: Rid,
    #[init(val = Rid::Invalid)]
    sampler: Rid,
    failed: bool,
    /// Frames upscaled (read by the proof script / log).
    #[var]
    frames: i64,
    /// Frames on which the engine asked for a history reset (P5).
    #[var]
    resets: i64,
    /// Last |jitter| seen through RenderSceneData.get_taa_jitter (P2) — 0 with jitter_phase_count 0.
    #[var]
    last_jitter_len: f64,
}

impl PassthroughUpscaler {
    fn ensure_pipeline(&mut self, rd: &mut Gd<RenderingDevice>) -> bool {
        if self.pipeline.is_valid() {
            return true;
        }
        if self.failed {
            return false;
        }
        let mut src = RdShaderSource::new_gd();
        src.set_stage_source(ShaderStage::COMPUTE, BLIT_GLSL);
        let Some(spirv) = rd.shader_compile_spirv_from_source(&src) else {
            godot_error!("PassthroughUpscaler: SPIR-V compile returned nothing");
            self.failed = true;
            return false;
        };
        let err = spirv.get_stage_compile_error(ShaderStage::COMPUTE);
        if !err.is_empty() {
            godot_error!("PassthroughUpscaler: shader compile error: {err}");
            self.failed = true;
            return false;
        }
        self.shader = rd.shader_create_from_spirv(&spirv);
        if !self.shader.is_valid() {
            self.failed = true;
            return false;
        }
        self.pipeline = rd.compute_pipeline_create(self.shader);
        let mut ss = RdSamplerState::new_gd();
        ss.set_mag_filter(SamplerFilter::LINEAR);
        ss.set_min_filter(SamplerFilter::LINEAR);
        ss.set_repeat_u(SamplerRepeatMode::CLAMP_TO_EDGE);
        ss.set_repeat_v(SamplerRepeatMode::CLAMP_TO_EDGE);
        self.sampler = rd.sampler_create(&ss);
        self.pipeline.is_valid()
    }
}

#[godot_api]
impl IViewportUpscaler for PassthroughUpscaler {
    fn render_callback(&mut self, render_data: Option<Gd<RenderData>>) {
        let Some(render_data) = render_data else { return };
        let Some(buffers) = render_data.get_render_scene_buffers() else { return };
        let Ok(buffers) = buffers.try_cast::<RenderSceneBuffersRd>() else { return };
        let Some(mut rd) = RenderingServer::singleton().get_rendering_device() else { return };
        if !self.ensure_pipeline(&mut rd) {
            return;
        }

        // P2 / P5 inputs: read every frame so the bindings are exercised (a pass-through needs none of them).
        if let Some(scene) = render_data.get_render_scene_data() {
            self.last_jitter_len = scene.get_taa_jitter().length() as f64;
        }
        if buffers.get_reset_accumulation() {
            self.resets += 1;
        }

        let target = buffers.get_target_size();
        let groups_x = ((target.x + 7) / 8) as u32;
        let groups_y = ((target.y + 7) / 8) as u32;
        for view in 0..buffers.get_view_count() {
            let color = buffers.get_color_layer(view);
            let upscaled = buffers.get_upscaled_layer(view);

            let mut u_src = RdUniform::new_gd();
            u_src.set_uniform_type(UniformType::SAMPLER_WITH_TEXTURE);
            u_src.set_binding(0);
            u_src.add_id(self.sampler);
            u_src.add_id(color);
            let mut u_dst = RdUniform::new_gd();
            u_dst.set_uniform_type(UniformType::IMAGE);
            u_dst.set_binding(1);
            u_dst.add_id(upscaled);
            let uniforms: Array<Gd<RdUniform>> = array![&u_src, &u_dst];
            let set = UniformSetCacheRd::get_cache(self.shader, 0, &uniforms);

            let list = rd.compute_list_begin();
            rd.compute_list_bind_compute_pipeline(list, self.pipeline);
            rd.compute_list_bind_uniform_set(list, set, 0);
            rd.compute_list_dispatch(list, groups_x, groups_y, 1);
            rd.compute_list_end();
        }
        self.frames += 1;
    }
}
