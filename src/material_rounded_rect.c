#include <lua.h>
#include <lauxlib.h>
#include <stddef.h>
#include <stdint.h>

#include "sokol/sokol_gfx.h"
#include "rounded_rect.glsl.h"
#include "solunaapi.h"

#define ROUNDED_RECT_STREAM_N 2

struct color {
	unsigned char channel[4];
};

struct rounded_payload {
	float a;
	float b;
	struct color color;
};

struct rounded_inst {
	float rect[4];
	float shape[4];
	struct color fill_color;
	struct color border_color;
};

struct material_rounded_rect {
	sg_pipeline pip;
	sg_buffer inst;
	struct soluna_render_bindings bind;
	vs_params_t *uniform;
	void *tmp_ptr;
	size_t tmp_size;
	int base;
};

struct rounded_stream_context {
	float width;
	float height;
	float radius;
	float border_width;
	struct rounded_payload payload[ROUNDED_RECT_STREAM_N];
};

static int material_id = 0;

static void
push_material_stream_string(lua_State *L, struct soluna_material_stream *stream) {
	lua_pushlstring(L, stream->data, stream->size);
	soluna_material_stream_free(stream->data);
	stream->data = NULL;
	stream->size = 0;
}

static lua_Number
check_number_field(lua_State *L, const char *name) {
	lua_Number value;
	if (lua_getfield(L, 1, name) == LUA_TNIL) {
		luaL_error(L, "Missing rounded rect field: %s", name);
		return 0.0;
	}
	value = luaL_checknumber(L, -1);
	lua_pop(L, 1);
	return value;
}

static lua_Number
opt_number_field(lua_State *L, const char *name, lua_Number fallback) {
	lua_Number value;
	if (lua_getfield(L, 1, name) == LUA_TNIL) {
		lua_pop(L, 1);
		return fallback;
	}
	value = luaL_checknumber(L, -1);
	lua_pop(L, 1);
	return value;
}

static lua_Integer
check_integer_field(lua_State *L, const char *name) {
	lua_Integer value;
	if (lua_getfield(L, 1, name) == LUA_TNIL) {
		luaL_error(L, "Missing rounded rect field: %s", name);
		return 0;
	}
	value = luaL_checkinteger(L, -1);
	lua_pop(L, 1);
	return value;
}

static lua_Integer
opt_integer_field(lua_State *L, const char *name, lua_Integer fallback) {
	lua_Integer value;
	if (lua_getfield(L, 1, name) == LUA_TNIL) {
		lua_pop(L, 1);
		return fallback;
	}
	value = luaL_checkinteger(L, -1);
	lua_pop(L, 1);
	return value;
}

static struct color
color_from_u32(uint32_t color) {
	struct color c;
	if (!(color & 0xff000000u)) {
		color |= 0xff000000u;
	}
	c.channel[0] = (unsigned char)((color >> 16) & 0xff);
	c.channel[1] = (unsigned char)((color >> 8) & 0xff);
	c.channel[2] = (unsigned char)(color & 0xff);
	c.channel[3] = (unsigned char)((color >> 24) & 0xff);
	return c;
}

static sg_pipeline
make_pipeline(sg_pipeline_desc *desc) {
	sg_shader shd = sg_make_shader(rounded_rect_shader_desc(sg_query_backend()));
	desc->shader = shd;
	desc->primitive_type = SG_PRIMITIVETYPE_TRIANGLE_STRIP;
	desc->label = "playground-rounded-rect-pipeline";
	desc->layout.buffers[0].step_func = SG_VERTEXSTEP_PER_INSTANCE;
	desc->colors[0].blend = (sg_blend_state) {
		.enabled = true,
		.src_factor_rgb = SG_BLENDFACTOR_SRC_ALPHA,
		.dst_factor_rgb = SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
		.src_factor_alpha = SG_BLENDFACTOR_ONE,
		.dst_factor_alpha = SG_BLENDFACTOR_ZERO,
	};
	return sg_make_pipeline(desc);
}

static void
submit(void *m_, struct soluna_material_stream_context ctx, int n) {
	struct material_rounded_rect *m = (struct material_rounded_rect *)m_;
	struct rounded_inst *tmp = (struct rounded_inst *)m->tmp_ptr;
	int out_n;
	int i;
	if (n % ROUNDED_RECT_STREAM_N != 0) {
		soluna_material_stream_error(ctx, "Invalid rounded rect stream count");
		return;
	}
	out_n = n / ROUNDED_RECT_STREAM_N;
	for (i = 0; i < out_n; i++) {
		int base = i * ROUNDED_RECT_STREAM_N;
		struct rounded_payload size_payload;
		struct rounded_payload shape_payload;
		struct soluna_material_stream_data size_data;
		struct soluna_material_stream_data shape_data;
		struct rounded_inst *inst = &tmp[i];
		if (!soluna_material_stream_read(ctx, base, sizeof(size_payload), &size_payload, &size_data)) {
			return;
		}
		if (!soluna_material_stream_read(ctx, base + 1, sizeof(shape_payload), &shape_payload, &shape_data)) {
			return;
		}
		inst->rect[0] = size_data.x;
		inst->rect[1] = size_data.y;
		inst->rect[2] = size_payload.a;
		inst->rect[3] = size_payload.b;
		inst->shape[0] = shape_payload.a;
		inst->shape[1] = shape_payload.b;
		inst->shape[2] = 0.0f;
		inst->shape[3] = 0.0f;
		inst->fill_color = size_payload.color;
		inst->border_color = shape_payload.color;
		(void)shape_data;
	}
	sg_append_buffer(m->inst, &(sg_range) { tmp, out_n * sizeof(tmp[0]) });
}

static int
lmaterial_rounded_rect_submit(lua_State *L) {
	struct material_rounded_rect *m = (struct material_rounded_rect *)luaL_checkudata(
		L,
		1,
		"PLAYGROUND_MATERIAL_ROUNDED_RECT"
	);
	int inst_batch_n = (int)(m->tmp_size / sizeof(struct rounded_inst));
	const void *stream;
	int prim_n;
	soluna_material_error err;
	if (inst_batch_n < 1) {
		return luaL_error(L, "Rounded rect tmp buffer is too small");
	}
	stream = lua_touserdata(L, 2);
	prim_n = luaL_checkinteger(L, 3);
	err = soluna_material_submit(stream, prim_n, material_id, inst_batch_n * ROUNDED_RECT_STREAM_N, m, submit);
	if (err != NULL) {
		return luaL_error(L, "%s", err);
	}
	return 0;
}

static int
lmaterial_rounded_rect_draw(lua_State *L) {
	struct material_rounded_rect *m = (struct material_rounded_rect *)luaL_checkudata(
		L,
		1,
		"PLAYGROUND_MATERIAL_ROUNDED_RECT"
	);
	int prim_n = luaL_checkinteger(L, 3);
	int rect_n;
	sg_bindings bindings;
	if (prim_n <= 0) {
		return 0;
	}
	if (prim_n % ROUNDED_RECT_STREAM_N != 0) {
		return luaL_error(L, "Invalid rounded rect primitive count");
	}
	rect_n = prim_n / ROUNDED_RECT_STREAM_N;
	sg_apply_pipeline(m->pip);
	sg_apply_uniforms(UB_vs_params, &(sg_range) { m->uniform, sizeof(vs_params_t) });
	bindings = soluna_material_bindings(m->bind);
	bindings.vertex_buffer_offsets[0] += (size_t)m->base * sizeof(struct rounded_inst);
	sg_apply_bindings(&bindings);
	sg_draw(0, 4, rect_n);
	m->base += rect_n;
	return 0;
}

static int
lmaterial_rounded_rect_reset(lua_State *L) {
	struct material_rounded_rect *m = (struct material_rounded_rect *)luaL_checkudata(
		L,
		1,
		"PLAYGROUND_MATERIAL_ROUNDED_RECT"
	);
	m->base = 0;
	return 0;
}

static int
lset_material_id(lua_State *L) {
	int id = luaL_checkinteger(L, 1);
	if (id <= 0) {
		return luaL_error(L, "Invalid rounded rect material id %d", id);
	}
	material_id = id;
	return 0;
}

static void
init_pipeline(struct material_rounded_rect *m) {
	sg_pipeline_desc desc = {
		.layout.attrs = {
			[ATTR_rounded_rect_rect].format = SG_VERTEXFORMAT_FLOAT4,
			[ATTR_rounded_rect_shape].format = SG_VERTEXFORMAT_FLOAT4,
			[ATTR_rounded_rect_fill_color].format = SG_VERTEXFORMAT_UBYTE4N,
			[ATTR_rounded_rect_border_color].format = SG_VERTEXFORMAT_UBYTE4N,
		},
	};
	m->pip = make_pipeline(&desc);
}

static int
lnew_material_rounded_rect(lua_State *L) {
	struct material_rounded_rect *m;
	int material_index;
	luaL_checktype(L, 1, LUA_TTABLE);
	m = (struct material_rounded_rect *)lua_newuserdatauv(L, sizeof(*m), 4);
	material_index = lua_gettop(L);
	init_pipeline(m);
	m->base = 0;

	if (lua_getfield(L, 1, "inst_buffer") != LUA_TUSERDATA) {
		return luaL_error(L, "Invalid key .inst_buffer");
	}
	luaL_checkudata(L, -1, "SOKOL_BUFFER");
	lua_pushvalue(L, -1);
	lua_setiuservalue(L, material_index, 1);
	lua_pushlightuserdata(L, &m->inst);
	lua_call(L, 1, 0);

	if (lua_getfield(L, 1, "bindings") != LUA_TUSERDATA) {
		return luaL_error(L, "Invalid key .bindings");
	}
	m->bind = (struct soluna_render_bindings) {
		.ctx = luaL_checkudata(L, -1, "SOKOL_BINDINGS"),
	};
	lua_pushvalue(L, -1);
	lua_setiuservalue(L, material_index, 2);
	lua_pop(L, 1);

	if (lua_getfield(L, 1, "uniform") != LUA_TUSERDATA) {
		return luaL_error(L, "Invalid key .uniform");
	}
	m->uniform = (vs_params_t *)luaL_checkudata(L, -1, "SOKOL_UNIFORM");
	lua_pushvalue(L, -1);
	lua_setiuservalue(L, material_index, 3);
	lua_pop(L, 1);

	if (lua_getfield(L, 1, "tmp_buffer") != LUA_TUSERDATA) {
		return luaL_error(L, "Invalid key .tmp_buffer");
	}
	if (lua_getmetatable(L, -1)) {
		return luaL_error(L, "Not an userdata without metatable");
	}
	m->tmp_ptr = lua_touserdata(L, -1);
	m->tmp_size = lua_rawlen(L, -1);
	lua_setiuservalue(L, material_index, 4);

	if (luaL_newmetatable(L, "PLAYGROUND_MATERIAL_ROUNDED_RECT")) {
		luaL_Reg l[] = {
			{ "__index", NULL },
			{ "reset", lmaterial_rounded_rect_reset },
			{ "submit", lmaterial_rounded_rect_submit },
			{ "draw", lmaterial_rounded_rect_draw },
			{ NULL, NULL },
		};
		luaL_setfuncs(L, l, 0);
		lua_pushvalue(L, -1);
		lua_setfield(L, -2, "__index");
	}
	lua_setmetatable(L, -2);
	return 1;
}

static void
write_rounded_rect_stream(void *ud, int index, struct soluna_material_stream_item *item) {
	struct rounded_stream_context *ctx = (struct rounded_stream_context *)ud;
	struct rounded_payload *payload = &ctx->payload[index];
	item->x = 0.0f;
	item->y = 0.0f;
	item->sprite = -1;
	if (index == 0) {
		payload->a = ctx->width;
		payload->b = ctx->height;
	} else {
		payload->a = ctx->radius;
		payload->b = ctx->border_width;
	}
	item->payload = payload;
}

static int
lrounded_rect(lua_State *L) {
	struct rounded_stream_context ctx;
	uint32_t fill_value;
	uint32_t border_value;
	struct soluna_material_stream stream;
	soluna_material_error err;
	if (material_id <= 0) {
		return luaL_error(L, "Rounded rect material is not registered");
	}
	luaL_checktype(L, 1, LUA_TTABLE);
	ctx.width = (float)check_number_field(L, "width");
	ctx.height = (float)check_number_field(L, "height");
	ctx.radius = (float)opt_number_field(L, "radius", 0.0);
	fill_value = (uint32_t)check_integer_field(L, "fill");
	border_value = (uint32_t)opt_integer_field(L, "border", fill_value);
	ctx.border_width = (float)opt_number_field(L, "border_width", 0.0);
	if (ctx.width <= 0.0f || ctx.height <= 0.0f) {
		return luaL_error(L, "Invalid rounded rect size");
	}
	if (ctx.radius < 0.0f || ctx.border_width < 0.0f) {
		return luaL_error(L, "Invalid rounded rect shape");
	}
	ctx.payload[0].color = color_from_u32(fill_value);
	ctx.payload[1].color = color_from_u32(border_value);
	err = soluna_material_push_stream(
		material_id,
		ROUNDED_RECT_STREAM_N,
		sizeof(struct rounded_payload),
		write_rounded_rect_stream,
		&ctx,
		&stream
	);
	if (err != NULL) {
		return luaL_error(L, "%s", err);
	}
	push_material_stream_string(L, &stream);
	return 1;
}

int
luaopen_playground_material_rounded_rect(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] = {
		{ "set_material_id", lset_material_id },
		{ "new", lnew_material_rounded_rect },
		{ "rect", lrounded_rect },
		{ "instance_size", NULL },
		{ NULL, NULL },
	};
	luaL_newlib(L, l);
	lua_pushinteger(L, sizeof(struct rounded_inst));
	lua_setfield(L, -2, "instance_size");
	return 1;
}
