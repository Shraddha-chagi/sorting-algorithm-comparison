import { useEffect, useMemo, useRef, useState } from 'react'
import { Line } from 'react-chartjs-2'
import {
  Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement,
  Tooltip, Legend, Filler
} from 'chart.js'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Tooltip, Legend, Filler)

const ALGORITHMS = ['Bubble Sort', 'Insertion Sort', 'Merge Sort']
const COLORS = ['#8b7cff', '#38d6c5', '#57a6ff']
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms))
const makeArray = (n, mode) => {
  const a = Array.from({ length: n }, () => Math.floor(Math.random() * 95) + 5)
  if (mode === 'sorted') return a.sort((x, y) => x - y)
  if (mode === 'reverse') return a.sort((x, y) => y - x)
  return a
}
function bubbleSort(input) {
  const a = [...input]; let comparisons = 0, swaps = 0
  for (let i = 0; i < a.length; i++) {
    for (let j = 0; j < a.length - i - 1; j++) {
      comparisons++
      if (a[j] > a[j + 1]) { [a[j], a[j + 1]] = [a[j + 1], a[j]]; swaps++ }
    }
  }
  return { comparisons, swaps }
}
function insertionSort(input) {
  const a = [...input]; let comparisons = 0, swaps = 0
  for (let i = 1; i < a.length; i++) {
    const key = a[i]; let j = i - 1
    while (j >= 0) {
      comparisons++
      if (a[j] <= key) break
      a[j + 1] = a[j]; swaps++; j--
    }
    a[j + 1] = key
  }
  return { comparisons, swaps }
}
function mergeSort(input) {
  let comparisons = 0, moves = 0
  const sort = a => {
    if (a.length <= 1) return a
    const mid = Math.floor(a.length / 2)
    const left = sort(a.slice(0, mid)), right = sort(a.slice(mid))
    const out = []; let i = 0, j = 0
    while (i < left.length && j < right.length) {
      comparisons++
      if (left[i] <= right[j]) out.push(left[i++]); else out.push(right[j++])
      moves++
    }
    while (i < left.length) { out.push(left[i++]); moves++ }
    while (j < right.length) { out.push(right[j++]); moves++ }
    return out
  }
  sort([...input])
  return { comparisons, swaps: moves }
}
function runAlgorithm(name, values) {
  const start = performance.now()
  let counts
  if (name === 'Bubble Sort') counts = bubbleSort(values)
  else if (name === 'Insertion Sort') counts = insertionSort(values)
  else counts = mergeSort(values)
  return { algorithm: name, size: values.length, inputType: 'Custom run', ms: +(performance.now() - start).toFixed(4), ...counts }
}
function mean(nums) { return nums.length ? nums.reduce((a, b) => a + b, 0) / nums.length : 0 }
function median(nums) {
  if (!nums.length) return 0
  const s = [...nums].sort((a, b) => a - b), m = Math.floor(s.length / 2)
  return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2
}
function stddev(nums) {
  if (nums.length < 2) return 0
  const m = mean(nums)
  return Math.sqrt(nums.reduce((sum, x) => sum + (x - m) ** 2, 0) / (nums.length - 1))
}
function downloadCsv(rows, filename = 'sortlab-results.csv') {
  if (!rows.length) { alert('There are no results to export yet. Run a benchmark or load a CSV first.'); return }
  const headers = [...new Set(rows.flatMap(row => Object.keys(row)))]
  const quote = value => `"${String(value ?? '').replaceAll('"', '""')}"`
  const csv = [headers.map(quote).join(','), ...rows.map(row => headers.map(h => quote(row[h])).join(','))].join('\r\n')
  const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8;' }))
  const a = document.createElement('a'); a.href = url; a.download = filename; a.click()
  URL.revokeObjectURL(url)
}
function normalizeRecord(row, dataset = 'Imported CSV') {
  const lower = Object.fromEntries(Object.entries(row).map(([k, v]) => [k.trim().toLowerCase().replaceAll(/[\s_-]+/g, ''), v]))
  const pick = (...keys) => { for (const k of keys) if (lower[k] !== undefined) return lower[k]; return undefined }
  const algorithm = String(pick('algorithm', 'sort', 'name') ?? '').trim()
  const rawRuntime = Number(pick('ms', 'runtime', 'runtime_ms', 'runtimeseconds', 'time', 'time_ms', 'executiontime', 'executiontimems'))
  if (!algorithm || !Number.isFinite(rawRuntime)) return null
  // The repository CSV stores seconds; the dashboard displays milliseconds.
  const ms = lower.runtimeseconds !== undefined ? rawRuntime * 1000 : rawRuntime
  return {
    algorithm: algorithm.toLowerCase().includes('bubble') ? 'Bubble Sort'
      : algorithm.toLowerCase().includes('insertion') ? 'Insertion Sort'
      : algorithm.toLowerCase().includes('merge') ? 'Merge Sort' : algorithm,
    size: Number(pick('size', 'inputsize', 'n', 'arraysize')) || 0,
    inputType: String(pick('inputtype', 'arrangement', 'case', 'distribution') ?? 'Imported CSV').replaceAll('_', ' '),
    ms,
    comparisons: Number(pick('comparisons', 'comparisoncount')) || 0,
    swaps: Number(pick('swaps', 'moves', 'swapcount')) || 0,
    correct: String(pick('correct', 'iscorrect', 'correctness')).toLowerCase() !== 'false',
    source: dataset
  }
}
function parseCsv(text, dataset = 'Imported CSV') {
  const lines = text.trim().split(/\r?\n/)
  if (lines.length < 2) return []
  // Supports ordinary comma-separated CSV with quoted fields.
  const split = line => {
    const out = []; let value = '', quoted = false
    for (let i = 0; i < line.length; i++) {
      const c = line[i]
      if (c === '"' && line[i + 1] === '"' && quoted) { value += '"'; i++ }
      else if (c === '"') quoted = !quoted
      else if (c === ',' && !quoted) { out.push(value); value = '' }
      else value += c
    }
    out.push(value); return out
  }
  const headers = split(lines[0]).map(h => h.trim())
  return lines.slice(1).map(line => {
    const values = split(line), row = {}
    headers.forEach((h, i) => row[h] = values[i] ?? '')
    return normalizeRecord(row, dataset)
  }).filter(Boolean)
}

export default function App() {
  const [inputSize, setInputSize] = useState(35)
  const [inputType, setInputType] = useState('random')
  const [speed, setSpeed] = useState(45)
  const [algorithm, setAlgorithm] = useState('Bubble Sort')
  const [array, setArray] = useState(() => makeArray(35, 'random'))
  const [active, setActive] = useState(null)
  const [running, setRunning] = useState(false)
  const [stats, setStats] = useState({ comparisons: 0, swaps: 0 })
  const [results, setResults] = useState([])
  const [csvRows, setCsvRows] = useState([])
  const [source, setSource] = useState('Study v2')
  const [sizeFilter, setSizeFilter] = useState('all')
  const [typeFilter, setTypeFilter] = useState('all')
  const [notice, setNotice] = useState('Loading your repository benchmark results…')
  const stopRef = useRef(false)

  useEffect(() => { setArray(makeArray(inputSize, inputType)); setStats({ comparisons: 0, swaps: 0 }) }, [inputSize, inputType])
  useEffect(() => {
    let cancelled = false
    async function loadRepositoryResults() {
      try {
        const [v1Response, v2Response] = await Promise.all([
          fetch(`${import.meta.env.BASE_URL}data/benchmark_results.csv`),
          fetch(`${import.meta.env.BASE_URL}data/benchmark_results_v2.csv`)
        ])
        if (!v1Response.ok || !v2Response.ok) throw new Error('Repository CSV files were not found.')
        const [v1Text, v2Text] = await Promise.all([v1Response.text(), v2Response.text()])
        const v1 = parseCsv(v1Text, 'Study v1')
        const v2 = parseCsv(v2Text, 'Study v2')
        if (!v1.length || !v2.length) throw new Error('Could not parse repository benchmark CSV files.')
        if (!cancelled) { setCsvRows([...v1, ...v2]); setNotice(`Loaded ${v1.length.toLocaleString()} rows from Study v1 and ${v2.length.toLocaleString()} rows from Study v2. Times converted from seconds to milliseconds.`) }
      } catch (error) { if (!cancelled) setNotice(`Could not auto-load repository data: ${error.message} You can still import a CSV below.`) }
    }
    loadRepositoryResults()
    return () => { cancelled = true }
  }, [])
  const allRows = useMemo(() => [
    ...results.map(r => ({ ...r, source: r.source || 'Live' })),
    ...csvRows
  ], [results, csvRows])
  const filtered = useMemo(() => allRows.filter(r =>
    (source === 'all' || r.source === source) &&
    (sizeFilter === 'all' || Number(r.size) === Number(sizeFilter)) &&
    (typeFilter === 'all' || String(r.inputType).toLowerCase() === typeFilter.toLowerCase())
  ), [allRows, source, sizeFilter, typeFilter])
  const sizes = [...new Set(allRows.map(r => Number(r.size)).filter(Boolean))].sort((a, b) => a - b)
  const types = [...new Set(allRows.map(r => String(r.inputType)).filter(Boolean))]
  const summary = ALGORITHMS.map(name => {
    const vals = filtered.filter(r => r.algorithm === name).map(r => Number(r.ms)).filter(Number.isFinite)
    return { name, count: vals.length, avg: mean(vals), median: median(vals), sd: stddev(vals) }
  })
  const chartData = {
    labels: summary.map(s => s.name),
    datasets: [{
      label: 'Mean runtime (ms)',
      data: summary.map(s => s.count ? +s.avg.toFixed(4) : null),
      borderColor: COLORS[0], backgroundColor: 'rgba(139,124,255,.16)',
      pointBackgroundColor: COLORS, pointRadius: 5, borderWidth: 2, tension: .3, fill: true
    }]
  }
  const chartOptions = {
    responsive: true, maintainAspectRatio: false,
    plugins: { legend: { labels: { color: '#aab4d0' } }, tooltip: { callbacks: { label: c => ` ${c.parsed.y ?? 'No data'} ms` } } },
    scales: {
      x: { ticks: { color: '#aab4d0' }, grid: { color: 'rgba(150,165,205,.08)' } },
      y: { beginAtZero: true, title: { display: true, text: 'Milliseconds', color: '#aab4d0' }, ticks: { color: '#aab4d0' }, grid: { color: 'rgba(150,165,205,.08)' } }
    }
  }
  async function startSort() {
    if (running) { stopRef.current = true; setRunning(false); setNotice('Pause requested.'); return }
    stopRef.current = false; setRunning(true); setActive(null)
    const a = [...array]; let comparisons = 0, swaps = 0
    const delay = Math.max(8, 160 - Number(speed) * 1.45)
    const mark = async (i, j, didSwap = false) => {
      if (stopRef.current) return false
      setActive([i, j]); setArray([...a])
      comparisons++; if (didSwap) swaps++
      setStats({ comparisons, swaps })
      await sleep(delay)
      return !stopRef.current
    }
    if (algorithm === 'Bubble Sort') {
      outer: for (let i = 0; i < a.length; i++) for (let j = 0; j < a.length - i - 1; j++) {
        if (!(await mark(j, j + 1))) break outer
        if (a[j] > a[j + 1]) { [a[j], a[j + 1]] = [a[j + 1], a[j]]; swaps++; setStats({ comparisons, swaps }) }
      }
    } else if (algorithm === 'Insertion Sort') {
      outer: for (let i = 1; i < a.length; i++) {
        const key = a[i]; let j = i - 1
        while (j >= 0 && a[j] > key) {
          if (!(await mark(j, j + 1, true))) break outer
          a[j + 1] = a[j]; j--; swaps++
        }
        a[j + 1] = key; setArray([...a])
      }
    } else {
      // Merge-sort animation displays each merge pass, keeping the visualizer responsive.
      let width = 1
      while (width < a.length && !stopRef.current) {
        for (let left = 0; left < a.length; left += 2 * width) {
          const mid = Math.min(left + width, a.length), right = Math.min(left + 2 * width, a.length)
          const merged = []; let i = left, j = mid
          while (i < mid && j < right) {
            comparisons++
            if (a[i] <= a[j]) merged.push(a[i++]); else merged.push(a[j++])
          }
          while (i < mid) merged.push(a[i++])
          while (j < right) merged.push(a[j++])
          for (let k = 0; k < merged.length; k++) { a[left + k] = merged[k]; swaps++ }
          setArray([...a]); setActive([left, right - 1]); setStats({ comparisons, swaps })
          await sleep(delay * 2)
        }
        width *= 2
      }
    }
    setArray([...a]); setActive(null); setRunning(false)
    if (!stopRef.current) {
      const row = runAlgorithm(algorithm, makeArray(inputSize, inputType))
      setNotice(`${algorithm} animation finished. The recorded benchmark is a separate timed run.`)
      setResults(old => [...old, { ...row, size: inputSize, inputType, source: 'Live' }])
    } else setNotice('Sorting paused. Press Start to run the current array again.')
  }
  function runBenchmark() {
    const sizesToTest = [100, 250, 500, 1000]
    const modes = inputType === 'random' ? ['random', 'sorted', 'reverse'] : [inputType]
    const rows = []
    for (const size of sizesToTest) for (const mode of modes) {
      const values = makeArray(size, mode)
      for (const name of ALGORITHMS) {
        const times = [], counters = []
        for (let rep = 0; rep < 3; rep++) {
          const row = runAlgorithm(name, values)
          times.push(row.ms); counters.push(row)
        }
        rows.push({
          algorithm: name, size, inputType: mode,
          ms: +mean(times).toFixed(4),
          stddevMs: +stddev(times).toFixed(4),
          comparisons: Math.round(mean(counters.map(r => r.comparisons))),
          swaps: Math.round(mean(counters.map(r => r.swaps))),
          repetitions: 3, source: 'Live'
        })
      }
    }
    setResults(old => [...old, ...rows])
    setNotice(`Benchmark complete: ${rows.length} summary rows added. These are local browser timings, not your original study's results.`)
  }
  async function importFile(event) {
    const file = event.target.files?.[0]
    if (!file) return
    try {
      const parsed = parseCsv(await file.text(), 'Imported CSV')
      if (!parsed.length) throw new Error('No usable rows found. CSV needs an algorithm column and a runtime/time column.')
      setCsvRows(old => [...old, ...parsed])
      setNotice(`Imported ${parsed.length} rows from ${file.name}. Check filters if the chart looks empty.`)
    } catch (e) { setNotice(`CSV import error: ${e.message}`) }
    event.target.value = ''
  }
  const best = summary.filter(s => s.count).sort((a, b) => a.avg - b.avg)[0]
  return <div className="app-shell">
    <aside className="sidebar">
      <a className="brand" href="#top"><span className="brand-icon">S</span><span>Sort<span className="accent">Lab</span><small>ALGORITHM STUDIO</small></span></a>
      <div className="nav-label">WORKSPACE</div>
      <a className="nav-item selected" href="#visualizer">▥ <span>Visualizer</span></a>
      <a className="nav-item" href="#analytics">◫ <span>Analytics</span></a>
      <a className="nav-item" href="#algorithms">⌘ <span>Algorithms</span></a>
      <div className="sidebar-bottom">
        <div className="status-dot"></div><span>Local computation</span>
        <p>Your array and benchmark runs stay in this browser session.</p>
        <a className="github-link" href="https://github.com/Shraddha-chagi/sorting-algorithm-comparison" target="_blank" rel="noreferrer">↗ View GitHub repository</a>
      </div>
    </aside>
    <main id="top" className="main-content">
      <header className="topbar"><div><span className="eyebrow">SORTING ALGORITHM COMPARISON</span><h1>Visualize. Benchmark. Understand.</h1><p>Explore how classic sorting algorithms behave across different inputs.</p></div><span className="top-pill"><span className="status-dot"></span> Browser-based</span></header>
      <section className="metric-grid">
        <article className="metric-card"><span className="metric-label">ALGORITHMS</span><strong>03</strong><span>Bubble, Insertion, Merge</span></article>
        <article className="metric-card"><span className="metric-label">RESULT ROWS</span><strong>{allRows.length.toLocaleString()}</strong><span>Repository + live results</span></article>
        <article className="metric-card"><span className="metric-label">FILTERED SAMPLES</span><strong>{filtered.length}</strong><span>Based on current filters</span></article>
        <article className="metric-card"><span className="metric-label">FASTEST IN VIEW</span><strong className="fastest">{best ? best.name.replace(' Sort', '') : '—'}</strong><span>{best ? `${best.avg.toFixed(4)} ms mean` : 'Load or generate results'}</span></article>
      </section>
      <section className="panel visualizer-panel" id="visualizer">
        <div className="section-heading"><div><span className="eyebrow">01 / INTERACTIVE LAB</span><h2>Sorting visualizer</h2><p>Watch values move into order, one operation at a time.</p></div><span className="live-badge"><span className="status-dot"></span>{running ? 'RUNNING' : 'READY'}</span></div>
        <div className="controls-grid">
          <label>Algorithm<select value={algorithm} onChange={e => setAlgorithm(e.target.value)} disabled={running}>{ALGORITHMS.map(x => <option key={x}>{x}</option>)}</select></label>
          <label>Input arrangement<select value={inputType} onChange={e => setInputType(e.target.value)} disabled={running}><option value="random">Random</option><option value="sorted">Already sorted</option><option value="reverse">Reverse sorted</option></select></label>
          <label>Array size <b>{inputSize}</b><input type="range" min="10" max="90" value={inputSize} onChange={e => setInputSize(Number(e.target.value))} disabled={running}/></label>
          <label>Animation speed <b>{speed}%</b><input type="range" min="1" max="100" value={speed} onChange={e => setSpeed(Number(e.target.value))}/></label>
        </div>
        <div className="bar-stage" aria-label="Array visualization">
          {array.map((value, i) => <div className={`bar ${active?.includes(i) ? 'bar-active' : ''}`} key={i} style={{ height: `${value}%` }} title={`Index ${i}: ${value}`}><span>{inputSize <= 24 ? value : ''}</span></div>)}
        </div>
        <div className="visualizer-footer"><div className="legend"><span><i className="legend-purple"></i>Values</span><span><i className="legend-cyan"></i>Compared / active</span></div><div className="button-row"><button className="btn primary" onClick={startSort}>{running ? 'Ⅱ Pause' : '▶ Start sorting'}</button><button className="btn secondary" disabled={running} onClick={() => { setArray(makeArray(inputSize, inputType)); setStats({ comparisons: 0, swaps: 0 }); setActive(null); setNotice('Array reset.') }}>↻ Reset</button><button className="btn secondary" disabled={running} onClick={() => { setArray(makeArray(inputSize, inputType)); setNotice('New array generated.') }}>＋ New array</button></div></div>
        <div className="operation-stats"><div><span>COMPARISONS</span><strong>{stats.comparisons.toLocaleString()}</strong></div><div><span>SWAPS / MOVES</span><strong>{stats.swaps.toLocaleString()}</strong></div><div><span>ARRAY SIZE</span><strong>{inputSize}</strong></div></div>
        <p className="notice" role="status">{notice}</p>
      </section>
      <section className="panel" id="analytics">
        <div className="section-heading"><div><span className="eyebrow">02 / EXPERIMENTS</span><h2>Performance analytics</h2><p>Explore your repository's 30-trial experiments, compare v1/v2, or import another dataset.</p></div><button className="btn secondary" onClick={() => downloadCsv(filtered)}>↓ Export CSV</button></div>
        <div className="filters">
          <label>Data source<select value={source} onChange={e => setSource(e.target.value)}><option value="all">All datasets</option><option value="Study v2">Repository study · v2</option><option value="Study v1">Repository study · v1</option><option value="Imported CSV">Imported CSV</option><option value="Live">Live browser benchmarks</option></select></label>
          <label>Input size<select value={sizeFilter} onChange={e => setSizeFilter(e.target.value)}><option value="all">All sizes</option>{sizes.map(n => <option key={n} value={n}>{n}</option>)}</select></label>
          <label>Input type<select value={typeFilter} onChange={e => setTypeFilter(e.target.value)}><option value="all">All types</option>{types.map(t => <option key={t} value={t}>{t}</option>)}</select></label>
          <label className="file-label">Import results CSV<input type="file" accept=".csv,text/csv" onChange={importFile}/></label>
        </div>
        <div className="chart-card"><div className="chart-title"><div><h3>Mean execution time</h3><p>Lower is faster · milliseconds</p></div><span className="chart-tag">CURRENT FILTER</span></div><div className="chart-wrap">{filtered.length ? <Line data={chartData} options={chartOptions}/> : <div className="empty-state"><span>⌁</span><strong>No benchmark data yet</strong><p>Import a CSV with algorithm and runtime columns, or run the benchmark below.</p></div>}</div></div>
        <div className="table-wrap"><table><thead><tr><th>ALGORITHM</th><th>SAMPLES</th><th>MEAN (MS)</th><th>MEDIAN (MS)</th><th>STD DEV (MS)</th></tr></thead><tbody>{summary.map((s, i) => <tr key={s.name}><td><span className="table-dot" style={{ background: COLORS[i] }}></span>{s.name}</td><td>{s.count}</td><td>{s.count ? s.avg.toFixed(4) : '—'}</td><td>{s.count ? s.median.toFixed(4) : '—'}</td><td>{s.count ? s.sd.toFixed(4) : '—'}</td></tr>)}</tbody></table></div>
        <div className="benchmark-row"><div><h3>Run a new browser benchmark</h3><p>Tests array sizes 100, 250, 500 and 1,000. Three repeats per algorithm and selected arrangement; these are new browser timings, separate from your 30-trial study.</p></div><button className="btn primary" onClick={runBenchmark}>▶ Run benchmark</button></div>
        <p className="footnote">Repository data includes 1,080 observations per CSV (3 algorithms × 4 sizes × 3 input types × 30 trials). Runtime seconds are converted to milliseconds for display. Browser timings are affected by your device, browser, background tasks, and timer precision. For a formal report, use repeated runs, keep methodology consistent, and distinguish these new measurements from your original experiment.</p>
      </section>
      <section className="panel algorithms-panel" id="algorithms"><div className="section-heading"><div><span className="eyebrow">03 / REFERENCE</span><h2>Algorithm quick guide</h2><p>Know what to expect before you run a test.</p></div></div><div className="algorithm-grid">
        <article className="algorithm-card"><span className="algo-number">01</span><h3>Bubble Sort</h3><p>Repeatedly compares adjacent elements and swaps them if they are out of order.</p><div className="complexity"><span>Average time</span><b>O(n²)</b></div><div className="complexity"><span>Extra space</span><b>O(1)</b></div></article>
        <article className="algorithm-card"><span className="algo-number cyan">02</span><h3>Insertion Sort</h3><p>Builds a sorted prefix by inserting each new element into its correct position.</p><div className="complexity"><span>Average time</span><b>O(n²)</b></div><div className="complexity"><span>Extra space</span><b>O(1)</b></div></article>
        <article className="algorithm-card"><span className="algo-number blue">03</span><h3>Merge Sort</h3><p>Divides the input, sorts smaller parts recursively, then merges them together.</p><div className="complexity"><span>Average time</span><b>O(n log n)</b></div><div className="complexity"><span>Extra space</span><b>O(n)</b></div></article>
      </div></section>
      <footer><span>SortLab · Sorting Algorithm Comparison</span><a href="https://github.com/Shraddha-chagi/sorting-algorithm-comparison" target="_blank" rel="noreferrer">Source code on GitHub ↗</a></footer>
    </main>
  </div>
}