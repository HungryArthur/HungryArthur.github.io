	shader_type canvas_item;

// Сюда мы передадим текстуру из SubViewport
uniform sampler2D map_texture;
// Радиус сглаживания края окружности
uniform float roughness : hint_range(0.0, 0.1) = 0.01;

void fragment() {
	// 1. Получаем координаты от центра тайла (от -0.5 до 0.5)
	vec2 center_uv = UV - 0.5;
	
	// 2. Высчитываем расстояние от центра до текущего пикселя (от 0 до 0.7)
	float dist = length(center_uv);
	
	// 3. Создаем маску окружности (0.5 - это радиус)
	float circle_mask = smoothstep(0.5, 0.5 - roughness, dist);
	
	// 4. Берем цвет из оригинальной текстуры мира
	vec4 map_color = texture(map_texture, UV);
	
	// 5. Умножаем прозрачность текстуры мира на прозрачность маски
	COLOR.rgb = map_color.rgb;
	COLOR.a = map_color.a * circle_mask;
}