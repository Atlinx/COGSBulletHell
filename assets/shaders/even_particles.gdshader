shader_type particles;

uniform int amount;
uniform float initial_velocity;
uniform sampler2D size_over_time;

void start(){
    float degree_to_rad = PI / 180.0;
	float angle_per_particle = 360.0 / float(amount);
    if(RESTART_VELOCITY){
	    float angle1_rad = float(INDEX) * angle_per_particle * degree_to_rad;
	    vec3 rot = vec3(cos(angle1_rad), sin(angle1_rad), 0.0);
	    VELOCITY = rot * initial_velocity;
	}
    if(RESTART_POSITION){
	    TRANSFORM[3] = vec4(0);
    }
}