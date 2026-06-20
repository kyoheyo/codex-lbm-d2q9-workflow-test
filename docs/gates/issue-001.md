# Gate: D2Q9 CUDA LBM Cylinder Wake

## Command

~~~powershell
powershell -ExecutionPolicy Bypass -File scripts\validate.ps1
~~~

## Pass Criteria

- Exit code is 0.
- Output contains LBM_TESTS_OK.
- Output contains LBM_VALIDATION_OK.
- At least 120 iterations are reported.
- out/cylinder_wake.csv exists and is non-empty.
- All builder changes stay within lane scope.
- The final integration branch passes this gate after all accepted branches are merged.

