// Swaying grass / cattail tufts drawn as crossed quads in a MultiMesh.
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D tex : source_color, filter_nearest;
uniform float strength = 0.12;
// a blow of Sora's: x, z where it landed, seconds since, its radius (combat.gd plants_hit); tall plants only
// (hit_amp 1, the owner, 2026-10-28: "잔디를 제외한 키 큰 식물들은 소라의 공격이 닿으면 심하게 흔들리는 효과")
uniform vec4 hit = vec4(0.0, 0.0, 99.0, 0.0);
uniform float hit_amp = 0.0;

void vertex() {
	vec3 o = MODEL_MATRIX[3].xyz;
	float s = sin(TIME * 1.7 + o.x * 0.6 + o.z * 0.4) + 0.4 * sin(TIME * 3.1 + o.x * 1.3);
	VERTEX.x += s * strength * VERTEX.y;
	VERTEX.z += s * strength * 0.5 * VERTEX.y;
	if (hit_amp > 0.0 && hit.z < 1.2) {
		vec2 d = o.xz - hit.xy;
		float dist = length(d);
		if (dist < hit.w) {
			// thrown away from the blow, then swinging back and forth as it dies down
			float a = hit_amp * (1.0 - dist / hit.w) * exp(-hit.z * 3.2) * sin(hit.z * 24.0 + 1.2);
			vec2 dir = dist > 0.01 ? d / dist : vec2(1.0, 0.0);
			vec3 ld = normalize((vec4(dir.x, 0.0, dir.y, 0.0) * MODEL_MATRIX).xyz); // into the tuft's own turned frame
			VERTEX.xz += ld.xz * a * 0.6 * VERTEX.y;
		}
	}
	NORMAL = vec3(0.0, 1.0, 0.0); // even, soft lighting on both sides
}

void fragment() {
	vec4 c = texture(tex, UV);
	ALBEDO = c.rgb * COLOR.rgb;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 1.0;
}
