shader_type canvas_item;

uniform float radius; // Radius of the cutout circle
uniform vec2 player_pos; // Position of the player in world coordinates
uniform vec2 screen_size; // Size of the screen

void fragment() {
	// Calculate the distance from the current fragment to the player position
	vec2 frag_pos = SCREEN_UV * screen_size;
	float distance = distance(player_pos, frag_pos);

	// Calculate the alpha value based on the distance and the radius
	float alpha = smoothstep(radius, radius + 0.1, distance);

	// Output the final color with the cutout circle
	vec4 bg_color = vec4(0.0, 0.0, 0.0, 0.8); // Dark opaque black color
	COLOR = vec4(bg_color.rgb, alpha);
}
