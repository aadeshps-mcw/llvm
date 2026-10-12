; RUN: opt < %s -passes=loop-vectorize -force-vector-width=4 -force-vector-interleave=1 -S | FileCheck %s

; On a SPIR/SPIR-V target, FPBuiltinFnSelection never runs (it is scheduled as
; a CodeGen pass, and SPIR-V emission bypasses CodeGen for a separate
; translator). The translator expects fpbuiltin calls in their original,
; scalar form, so the Loop Vectorizer must not widen them here, unlike on a
; normal host target (see LoopVectorize/fpbuiltin.ll).
target triple = "spir64-unknown-unknown"

define void @sqrt(ptr noalias %in, ptr noalias %out, i64 %n) {
; CHECK-LABEL: @sqrt(
; CHECK-NOT: call {{.*}} @llvm.fpbuiltin.sqrt.v
; CHECK: call float @llvm.fpbuiltin.sqrt.f32(float {{.*}})
entry:
  br label %loop
loop:
  %iv = phi i64 [ 0, %entry ], [ %iv.next, %loop ]
  %p.in = getelementptr inbounds float, ptr %in, i64 %iv
  %x = load float, ptr %p.in, align 4
  %r = call float @llvm.fpbuiltin.sqrt.f32(float %x) #0
  %p.out = getelementptr inbounds float, ptr %out, i64 %iv
  store float %r, ptr %p.out, align 4
  %iv.next = add nuw nsw i64 %iv, 1
  %done = icmp eq i64 %iv.next, %n
  br i1 %done, label %exit, label %loop
exit:
  ret void
}

attributes #0 = { "fpbuiltin-max-error"="1.0" }
