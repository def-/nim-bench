import times, posix

when defined(x86_64):
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

proc getTime: float {.inline.} =
  var ts: TTimespec
  discard clock_gettime(CLOCK_MONOTONIC, ts)
  float(ts.tv_sec) + float(ts.tv_nsec) * 1e-9

proc getCPUTime: float {.inline.} =
  var ts: TTimespec
  discard clock_gettime(CLOCK_PROCESS_CPUTIME_ID, ts)
  float(ts.tv_sec) + float(ts.tv_nsec) * 1e-9

proc doWork: int =
  result = 0
  for i in 1..100:
    result += i*i

proc fib(n: int): int =
  case n
  of 0: 0
  of 1: 1
  else: fib(n-1) + fib(n-2)

proc avg[T](xs: varargs[T]): T =
  for x in xs:
    result += x
  result = result div xs.len

type Measure = object
  time, cpuTime: float
  cycles: int64

template measure(n: int, body: stmt): expr =
  var ms = newSeq[Measure](n)
  for m in ms.mitems:
    let t1 = getTime()
    let p1 = getCPUTime()
    let c1 = getCycles()
    body
    let t2 = getTime()
    let p2 = getCPUTime()
    let c2 = getCycles()
    m.cycles = c2-c1
    m.time = t2-t1
    m.cpuTime = p2-p1
  ms

template benchmark(name: expr, body: stmt): stmt {.immediate.} =
  block:
    # TODO: Do something with the name
    body

template bench(name: expr, body: stmt): stmt {.immediate.} =
  block:
    # TODO: Do something with the name

    var os = avg measure(1000, (discard)).map(proc(x: Measure): int64 = x.cycles)
    #echo os

    var ms = measure(1000, body)
    var avg: int64
    for m in ms:
      #echo m.cycles - os
      avg += m.cycles
    avg = avg div ms.len
    echo name, " ", avg-os

benchmark "Test Bench":
  bench "test1":
    var x = fib(1)

  bench "test2":
    var x = fib(10)
