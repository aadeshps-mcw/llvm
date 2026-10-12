; RUN: split-file %s %t
; RUN: opt -alt-math-library=svml -fpbuiltin-fn-selection -S < %t/width-mismatch.ll | FileCheck %s --check-prefix=WIDTH-MISMATCH
; RUN: opt -alt-math-library=test -fpbuiltin-fn-selection -S < %t/no-entry.ll | FileCheck %s --check-prefix=NO-ENTRY

; Neither case has an exact-width alt-math-library entry, so
; FPBuiltinFnSelection must scalarize the call lane-by-lane instead of
; reporting a fatal error, since a scalar (VF=1) entry is always available.

;--- width-mismatch.ll
; SVML only has erf at widths 1/4/8/16, not 32.
target triple = "x86_64-unknown-linux-gnu"

; WIDTH-MISMATCH-LABEL: @erf_bad_width(
; WIDTH-MISMATCH-NOT: @__svml_erff{{[48]|16|32}}
; WIDTH-MISMATCH-COUNT-32: call float @__svml_erff1_ha(float {{.*}})
; WIDTH-MISMATCH: ret <32 x float>
define <32 x float> @erf_bad_width(<32 x float> %a) {
  %r = call <32 x float> @llvm.fpbuiltin.erf.v32f32(<32 x float> %a) #0
  ret <32 x float> %r
}

attributes #0 = { "fpbuiltin-max-error"="1.0" }

;--- no-entry.ll
; The "test" library only defines a scalar tan; no vector width at all.
target triple = "x86_64-unknown-linux-gnu"

; NO-ENTRY-LABEL: @tan_v4(
; NO-ENTRY:      [[E0:%.*]] = extractelement <4 x float> %a, i64 0
; NO-ENTRY-NEXT: [[C0:%.*]] = call float @__test_altmath_tanf_high(float [[E0]])
; NO-ENTRY-NEXT: [[I0:%.*]] = insertelement <4 x float> poison, float [[C0]], i64 0
; NO-ENTRY-NEXT: [[E1:%.*]] = extractelement <4 x float> %a, i64 1
; NO-ENTRY-NEXT: [[C1:%.*]] = call float @__test_altmath_tanf_high(float [[E1]])
; NO-ENTRY-NEXT: [[I1:%.*]] = insertelement <4 x float> [[I0]], float [[C1]], i64 1
; NO-ENTRY-NEXT: [[E2:%.*]] = extractelement <4 x float> %a, i64 2
; NO-ENTRY-NEXT: [[C2:%.*]] = call float @__test_altmath_tanf_high(float [[E2]])
; NO-ENTRY-NEXT: [[I2:%.*]] = insertelement <4 x float> [[I1]], float [[C2]], i64 2
; NO-ENTRY-NEXT: [[E3:%.*]] = extractelement <4 x float> %a, i64 3
; NO-ENTRY-NEXT: [[C3:%.*]] = call float @__test_altmath_tanf_high(float [[E3]])
; NO-ENTRY-NEXT: [[I3:%.*]] = insertelement <4 x float> [[I2]], float [[C3]], i64 3
; NO-ENTRY-NEXT: ret <4 x float> [[I3]]
define <4 x float> @tan_v4(<4 x float> %a) {
  %r = call <4 x float> @llvm.fpbuiltin.tan.v4f32(<4 x float> %a) #0
  ret <4 x float> %r
}

attributes #0 = { "fpbuiltin-max-error"="1.0" }
