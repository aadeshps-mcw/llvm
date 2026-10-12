; RUN: opt < %s -passes=loop-vectorize -alt-math-library=test -force-vector-width=4 -force-vector-interleave=1 -S | FileCheck %s

target triple = "x86_64-unknown-linux-gnu"

; The "test" alt-math library only defines a scalar (VF=1) implementation of
; tan, so there is no v4f32 entry for the Loop Vectorizer to widen this call
; to. canWidenFPBuiltinCall must steer the cost model and call-widening
; decision away from committing to that VF for the call: the surrounding
; loads/stores still vectorize, but the call itself is scalarized lane-by-lane
; instead of being widened to an unsupported llvm.fpbuiltin.tan.v4f32.
; CHECK-LABEL: @tan_no_v4(
; CHECK-NOT: call <4 x float> @llvm.fpbuiltin.tan.v4f32(
; CHECK: extractelement <4 x float>
; CHECK-NEXT: call float @llvm.fpbuiltin.tan.f32(float {{.*}})
define void @tan_no_v4(ptr noalias %in, ptr noalias %out, i64 %n) {
entry:
  br label %loop
loop:
  %iv = phi i64 [ 0, %entry ], [ %iv.next, %loop ]
  %p.in = getelementptr inbounds float, ptr %in, i64 %iv
  %x = load float, ptr %p.in, align 4
  %r = call float @llvm.fpbuiltin.tan.f32(float %x) #0
  %p.out = getelementptr inbounds float, ptr %out, i64 %iv
  store float %r, ptr %p.out, align 4
  %iv.next = add nuw nsw i64 %iv, 1
  %done = icmp eq i64 %iv.next, %n
  br i1 %done, label %exit, label %loop
exit:
  ret void
}

attributes #0 = { "fpbuiltin-max-error"="1.0" }
