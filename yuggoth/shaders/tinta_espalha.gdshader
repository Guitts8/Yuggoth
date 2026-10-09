// A tinta que se espalha pela tela a partir de um ponto (o Necronomicon, ao
// começar ou continuar o jogo: a entrada escolhida se derrama e o livro afunda
// no preto). A borda é irregular (o ruído) e tem um debrum rubro, a tinta fresca.
shader_type canvas_item;

uniform float progresso : hint_range(0.0, 1.0) = 0.0;
uniform vec2 centro = vec2(0.5, 0.5);
uniform float proporcao = 1.777;
uniform sampler2D ruido : filter_linear_mipmap, repeat_enable;

void fragment() {
	vec2 d = (UV - centro) * vec2(proporcao, 1.0);
	float dist = length(d);
	float angulo = atan(d.y, d.x);
	// Línguas de tinta: o raio varia com o ângulo e com o ruído do papel.
	// O ruído em volta de um círculo (sem emenda onde o ângulo dá a volta).
	float lingua = texture(ruido, vec2(cos(angulo), sin(angulo)) * 0.35 + vec2(progresso * 0.2, 0.0)).r;
	float fibra = texture(ruido, UV * vec2(proporcao, 1.0) * 3.0).r;
	float raio = progresso * progresso * 2.4 * (0.75 + 0.5 * lingua) + (fibra - 0.5) * 0.08;
	float dentro = smoothstep(raio, raio - 0.02, dist);
	float debrum = smoothstep(raio + 0.01, raio - 0.005, dist) - smoothstep(raio - 0.005, raio - 0.05, dist);
	vec3 cor = mix(vec3(0.012, 0.006, 0.004), vec3(0.32, 0.03, 0.02), clamp(debrum, 0.0, 1.0));
	COLOR = vec4(cor, clamp(dentro + debrum * 0.8, 0.0, 1.0));
}
