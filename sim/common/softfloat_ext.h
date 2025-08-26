#include <stdint.h>
#include <softfloat_types.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct { uint8_t v; } float8_t;  // e4m3
typedef struct { uint8_t v; } bfloat8_t; // e5m2

uint_fast16_t f16_classify(float16_t);
float16_t f16_rsqrte7(float16_t);
float16_t f16_recip7(float16_t);

uint_fast16_t f32_classify(float32_t);
float32_t f32_rsqrte7(float32_t);
float32_t f32_recip7(float32_t);

uint_fast16_t f64_classify(float64_t);
float64_t f64_rsqrte7(float64_t);
float64_t f64_recip7(float64_t);

float8_t f32_to_f8e4m3(float32_t);
float32_t f8e4m3_to_f32(float8_t);

bfloat8_t f32_to_f8e5m2(float32_t);
float32_t f8e5m2_to_f32(bfloat8_t);

uint32_t cvt_f32_to_custom(float value, uint32_t exp_bits, uint32_t sig_bits,
                           uint32_t frm, uint32_t *fflags);

float cvt_custom_to_f32(uint32_t value, uint32_t exp_bits, uint32_t sig_bits,
                        uint32_t frm, uint32_t *fflags);

#ifdef __cplusplus
}
#endif