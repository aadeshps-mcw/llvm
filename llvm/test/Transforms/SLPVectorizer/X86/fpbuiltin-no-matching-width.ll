; RUN: opt < %s -mtriple=x86_64-unknown-linux-gnu -mcpu=skylake-avx512 -alt-math-library=test -passes=slp-vectorizer -slp-threshold=-100 -S | FileCheck %s

; The "test" alt-math library only defines a scalar (VF=1) implementation of
; tan, so there is no v2f32 entry for SLP to combine these two scalar calls
; into. canWidenFPBuiltinCall must steer getScalarsVectorizationState away
; from treating them as vectorizable to that width, so they are left as
; separate scalar calls instead of being combined into an unsupported
; llvm.fpbuiltin.tan.v2f32.
define void @tan_no_v2(ptr %in, ptr %out) {
; CHECK-LABEL: @tan_no_v2(
; CHECK-NOT: call <2 x float> @llvm.fpbuiltin.tan.v2f32(
; CHECK: call float @llvm.fpbuiltin.tan.f32(float %x0)
; CHECK: call float @llvm.fpbuiltin.tan.f32(float %x1)
  %x0 = load float, ptr %in, align 4
  %p1 = getelementptr inbounds float, ptr %in, i64 1
  %x1 = load float, ptr %p1, align 4
  %r0 = call float @llvm.fpbuiltin.tan.f32(float %x0) #0
  %r1 = call float @llvm.fpbuiltin.tan.f32(float %x1) #0
  store float %r0, ptr %out, align 4
  %q1 = getelementptr inbounds float, ptr %out, i64 1
  store float %r1, ptr %q1, align 4
  ret void
}

attributes #0 = { "fpbuiltin-max-error"="1.0" }
