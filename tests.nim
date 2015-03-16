import math

when defined(x86_64) or defined(macosx):
  proc getCycles: int64 {.inline.} =
    var hi,lo: uint32
    asm """
      "rdtsc" : "=a"(`lo`), "=d"(`hi`)
    """
    return int64(lo) or (int64(hi) shl 32)
else:
  proc getCycles: int64 {.inline.} =
    asm """
      "rdtsc" : "=A"(`result`)
    """

proc fib(n: int): int =
  case n
  of 0: 0
  of 1: 1
  else: fib(n-1) + fib(n-2)

proc `$`*(r: RunningStat): string =
  "{n=" & $r.n & " sum=" & $r.sum & " min=" & $r.min & " max=" & $r.max & " mean=" & $r.mean & "}"

template measure(n: int, body: stmt): RunningStat =
  ## Returning RunningStat so no array is needed and
  ## decreases any memory pressure. Also, more consistent
  ## results are obtained if RunningStat.min is used to
  ## report the cycles/loop (c/l), of course YMMV.
  var rs: RunningStat
  for idx in 0..n-1:
    let c1 = getCycles()
    body
    let c2 = getCycles()
    rs.push(float(c2-c1))
  rs

template benchmark(name: expr, body: stmt) {.immediate.} =
  block:
    # TODO: Do something with the name
    body

template bench(name: expr, body: stmt) {.immediate.} =
  block:
    # TODO: Do something with the name
    let
      # These need to be determined dynamically based on body and system speed
      # and these aren't enough to give totally consistent results. For test1
      # I see between 0.0c/l to 12.0c/l. For test2 it's 2450c/l 90% of the time
      # but once in awhile I see 2452c/l and 2454c/l.
      osLoops = 10_000_000
      msLoops = 100_000

    # Measure do nothing with enough work to get the
    # cpu going "fast". Hence the 10,000,000 loops which
    # on a late 2013 Macbook Pro 2.6GHz Core i7 is giving
    # a consistent of 12 c/l for os.min.
    var os = measure(osLoops, (discard))
    #echo name, " ", os.min, "c/l std=", standardDeviation(os), " os=", os

    # Measure work
    var ms = measure(msLoops, body)
    echo name, " ", ms.min - os.min, "c/l std=", standardDeviation(ms), " ms=", ms

benchmark "Test Bench":
  bench "test1":
    var x = fib(1)

  bench "test2":
    var x = fib(10)
