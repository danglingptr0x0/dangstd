# Global Development Standards

**Scope:** These standards apply to all repositories unless explicitly overridden by project-local documentation.

---

## 1. Definitions

| Term | Definition |
|------|------------|
| SHALL | Absolute requirement; non-compliance constitutes a violation |
| SHALL NOT | Absolute prohibition |
| SHOULD | Recommended practice; deviation requires justification |
| SHOULD NOT | Discouraged practice; usage requires justification |
| MAY | Optional; implementation discretion permitted |

---

## 2. Version Control

### 2.1 Global Hooks

Global hooks SHALL be located at `~/.config/git/hooks/` and enabled via:
```bash
git config --global core.hooksPath ~/.config/git/hooks
```

| Hook | Function |
|------|----------|
| `pre-commit` | Branch validation, binary blocking, formatting, static analysis |
| `prepare-commit-msg` | Auto-population of `type(scope):` from branch name |
| `commit-msg` | Conventional commit validation, scope matching |
| `pre-push` | Label warnings, WIP blocking, secrets scan, sanitizer tests |
| `pre-rebase` | Warning on pushed branches, blocking of main/staging |
| `post-checkout` | Regeneration of compile_commands.json, ccache statistics, stale branch warnings |

### 2.2 Scripts

Scripts SHALL be located at `~/.config/git/bin/` and added to PATH.

| Command | Function |
|---------|----------|
| `git cm "desc"` | Commit with auto-prefix derived from branch name |
| `git bump` | Display next semantic version from conventional commits |
| `git bump --apply` | Initiate git flow release with calculated version |
| `git release-notes` | Generate changelog via git-cliff |

### 2.3 Coccinelle

Semantic patches SHALL be located at `~/.config/git/cocci/`.

```bash
~/.config/git/cocci/run-all.sh /path/to/src        # Report mode
~/.config/git/cocci/run-all.sh /path/to/src --fix  # Apply mode (creates backup)
```

### 2.4 Branch Naming

Branch names SHALL conform to the pattern:
```
type/name
```

Valid type prefixes: `feat/` `fix/` `hot/` `rel/` `misc/` `docs/` `refactor/` `test/` `chore/` `perf/` `ci/` `build/` `revert/`

### 2.5 Commit Message Format

Commit messages SHALL conform to the pattern:
```
type(scope): description
```

- Total length SHALL be 75-100 characters
- Types: feat fix hot rel misc docs refactor test chore perf ci build revert
- Description SHALL use imperative mood
- Description SHALL NOT end with a period
- When committing, only the description SHALL be provided; `type(scope):` is auto-populated by `prepare-commit-msg` hook from branch name

### 2.6 Commit Atomicity

1. Each commit SHALL contain files from exactly one subsystem
2. Subsystem SHALL be defined as directory path + base filename
3. Scope in commit message SHALL match the subsystem
4. Header and source files with the same base name SHALL be committed together
5. CMakeLists.txt SHALL be treated as its own subsystem

### 2.7 Test State Tracking

All code SHALL be tested with minimum 50% coverage before committing.

| Command | Function |
|---------|----------|
| `git test-state save` | Record source hash + coverage after tests pass |
| `git test-state check` | Verify current code matches last tested state |

**Workflow:**
```bash
cmake -B build && cmake --build build
make -C build tests-run
git test-state save
git add -A && git commit
```

| Target | Function |
|--------|----------|
| `make tests` | Build all test executables (no run) |
| `make tests-run` | Build tests if needed, run ctest, generate coverage |

- Pre-commit hook automatically runs `git test-state check`
- Pre-commit hook blocks commits if CMakeLists.txt lacks coverage flags
- Coverage instrumentation is mandatory for all C/C++ projects
- State stored in `.test-state` (add to `.gitignore`)
- Coverage report generated in `build/coverage_html/`

**Required CMakeLists.txt configuration:**
```cmake
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} --coverage -fprofile-arcs -ftest-coverage")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage")
```

### 2.8 Git Flow

```bash
git flow feature start name   # Creates feat/name
git flow feature finish name  # Merges to staging
git flow release start 1.2.0  # Creates rel/1.2.0
git flow release finish 1.2.0 # Merges and tags
```

---

## 3. Project Planning

Prior to implementation:

1. All significant decision points SHALL be identified
2. Clarification SHALL be obtained on:
   - Architecture and module structure
   - API design and function signatures
   - Data flow and state management
   - Trade-offs between approaches
3. Implementation SHALL NOT proceed until decisions are confirmed

---

## 4. Implementation Rules

1. Functions SHALL NOT be stubbed; full implementations SHALL be provided
2. When modifying existing logic, changes SHALL be made incrementally
3. Stubs pollute symbol tables and mislead contributors inspecting function signatures

---

## 5. Code Exploration

Before reading any C source file, AST tools SHALL be used first:

```bash
ctags -x --c-kinds=f src/path/file.c              # Functions
ctags -x --c-kinds=st src/path/file.c             # Structs/typedefs
ctags -x --c-kinds=+defgstuvx src/path/file.c     # All symbols

ast-grep run --pattern 'static $RET $FUNC($$$)' --lang c file.c
ast-grep run --pattern 'typedef struct $NAME { $$$BODY }' --lang c file.c

# JSON output for bulk operations
ast-grep run --pattern 'int32_t func_name($$$) { $$$BODY }' --lang c file.c --json | jq '.[0].range'
```

---

## 6. Text Replacement

1. `sd` SHALL be used for text replacement; `sed` is prohibited
2. Dry-run validation SHALL precede application: `sd -p 'pattern' 'replacement' file`
3. `-F` flag SHALL be used for literal strings
4. Patterns SHALL be specific to avoid false positives

---

## 7. Code Style

### 7.1 Formatting

1. Emojis and decorative symbols SHALL NOT be used
2. Lines SHALL NOT be wrapped; horizontal scrolling is acceptable
3. Visual alignment via extra whitespace SHALL NOT be used; one space between type and symbol
4. Indentation SHALL be 4 spaces; tabs SHALL NOT be used
5. Function definitions SHALL use Allman braces (opening brace on new line)
6. Single-line guard clauses SHALL be formatted as: `if (UNLIKELY(!ptr)) { return ERR_FUNC_ARG_NULL; }`
7. Only single statements MAY be inlined
8. Nested single-statement structures SHALL remain on one line: `while (x) { if (y) { return z; } }`
9. Space SHALL follow keywords (`if`, `while`, `for`, `switch`); space SHALL NOT precede function call parentheses
10. Variable declarations SHALL be at top of scope block, initialized to 0/NULL
11. Unused return values SHALL be cast: `(void)memset(...)`

### 7.2 File Naming vs Symbol Naming

1. File names within a module directory SHALL NOT repeat the module prefix: `src/hwid/clock.c` (not `src/hwid/hwid_clock.c`)
2. Exception: top-level module file SHALL use module name: `src/hwid/hwid.c`, `src/hwid/hwid.h`
3. Symbol names (functions, types, macros) SHALL include the module prefix: `hwid_clock_collect()`, not `clock_collect()`

Rationale: File names appear with directory path providing context; symbols appear in grep results and debuggers without path context.

### 7.3 Function Names

1. Function names SHALL use snake_case, all lowercase
2. Function names SHALL follow the pattern: `module_noun_verb`
3. Getters SHALL follow the pattern: `module_noun_get`
4. Setters SHALL follow the pattern: `module_noun_set`
5. Boolean predicates SHALL follow the pattern: `module_noun_is`, `module_noun_has`
6. Callbacks SHALL follow the pattern: `module_noun_verb_cb`
7. Static/private functions SHALL follow the same patterns

### 7.4 Type Names

1. Enums SHALL be defined as: `typedef enum prefix_name { PREFIX_NAME_VALUE, ... } prefix_name_t;`
2. Structs SHALL be defined as: `typedef struct prefix_name { ... } prefix_name_t;`
3. Type names SHALL have `_t` suffix
4. Enum values SHALL use ALL_CAPS

### 7.5 Constants and Macros

1. Constants and macros SHALL use ALL_CAPS_SNAKE_CASE
2. Constants and macros SHALL have module prefix
3. Hardware constants SHALL define magic numbers with descriptive names: `#define FDC_RATE_500K 0x00`

### 7.6 Variables

1. Top-level declarations (globals, file-scope statics) SHALL NOT be used
2. Forward declarations SHALL NOT be used; the header defining the type SHALL be included
3. Backend abstraction: when a module has multiple backends (e.g., `net_ctx_t` with ENet and Steamworks), the generic struct SHALL declare a context-named `void *` field (e.g., `void *net`, `void *vk`); each backend implementation SHALL cast to its own type
4. Struct padding SHALL use explicit `uint8_t pudding[N]` fields
5. Cache-aligned structs SHALL use `__attribute__((aligned(64)))`
6. `double` SHALL be used exclusively for floating point; `float` is prohibited

### 7.7 Error Handling

1. Functions SHALL return `int32_t` with `*_ERR_*` codes
2. `UNLIKELY()` macro SHALL be used for error paths
3. Guard clauses SHALL be at function start with early return on error
4. `goto` and labels SHALL NOT be used; explicit cleanup in each error path SHALL be used instead
5. Pragmas to suppress warnings SHALL NOT be used; code SHALL be refactored to satisfy static analyzers

### 7.8 Comments

1. Comments SHALL be minimal — only section dividers (e.g., `// module`, `// subsystem`)
2. Doc comments, doxygen, and inline explanations SHALL NOT be used
3. Brief callback signature hints are permitted
4. Proper grammar and punctuation SHALL be used; semicolons SHALL separate clauses
5. Comments for obvious code SHALL NOT be written

### 7.9 Log Messages

1. Colons SHALL be used for key-value pairs: `"key: %u"` not `"key=%u"`
2. Semicolons SHALL separate multiple values: `"failed; key: %u; other: %s"`

### 7.10 Includes

1. Standard library includes SHALL precede project includes
2. Header guards SHALL follow: `#ifndef MODULE_H` / `#define MODULE_H` / `#endif`

### 7.11 Module Header Architecture

1. Core headers SHALL only include `<stdint.h>`, `<stddef.h>`, and other engine headers
2. External/third-party includes in `.h` files are prohibited
3. All backend handles SHALL be `void*` in headers
4. Implementation files SHALL cast `void*` to actual types
5. Wrapper functions that only call another function SHALL NOT be used; one function SHALL do the work

---

## 8. Required Abbreviations

The following abbreviations SHALL be used in identifiers; full words SHALL be avoided.

### 8.1 Core
```
sys=system  init=initialize  ctx=context  conf=config  desc=descriptor
func=function  cb=callback  attr=attribute  dev=device  fmt=format
idx=index  val=value  ptr=pointer  ret=return  err=error
src=source  dst=destination  len=length  buff=buffer  addr=address
alloc=allocation  dealloc=deallocation  cunt=count  cuntr=counter
pudding=padding  op=operator/operand  lhs=left  rhs=right
decl=declaration  def=definition  ref=reference
```

### 8.2 Concurrency
```
mut=mutex  cond=condition  sem=semaphore  sync=synchronization
proc=process  pool=pool  mngr=manager  shm=shared_memory
```

### 8.3 Data Structures
```
hdr=header  msg=message  req=request  resp=response  conn=connection
```

### 8.4 Math
```
mul=multiplication  div=division  mod=modulo
mat=matrix  vec=vector
```

### 8.5 Graphics/Rendering
```
tex=texture  mtl=material  vert=vertex  cam=camera
fbo=framebuffer  gbuff=g-buffer  fx=effects  grad=gradient
img=image  w=window
```

### 8.6 Physics
```
phys=physics  coll=collision  doll=ragdoll
bphase=broadphase  nphase=narrowphase
anim=animation  iter=iterative
```

### 8.7 Compiler/Language
```
tok=token  lex=lexer  sym=symbol  expr=expression  stmt=statement
reg=register  imm=immediate  mem=memory
```

### 8.8 Hardware/Kernel
```
isr=interrupt_service_routine  irq=interrupt_request
cmd=command  kb=keyboard  spkr=speaker
rd=read  wr=write  ident=identify
cyl=cylinder  sec=sector  secs=sectors  hd=head
```

### 8.9 Domain-Specific
```
sched=scheduler  strat=strategy  proj=project  cplx=complexity
pform=platform  econ=economy  lboard=leaderboard  wshop=workshop
enc=encrypt  dec=decrypt  sess=session
sub=subscription
```

### 8.10 Prohibited Terms
```
buf (use buff)  count (use cunt)  padding (use pudding)
float (use double)
```

---

## 9. Vale Configuration

Vale configuration SHALL be located at `~/.config/vale/`.

Enabled style packages: Microsoft, write-good, proselint, alex

```bash
vale file.md
```

---

## 10. libdangling

libdangling is the canonical utility library for all C projects. It SHALL be used for all utilities it provides; redefinition in project code is prohibited.

**Installation:** System-wide via `pkg-config --cflags --libs dangling`

**Source:** `~/git/libdangling`

### 10.1 Macros (`core/macros.h`, `core/bits.h`)

| Category | Macros |
|----------|--------|
| Branch hints | `LDG_LIKELY()`, `LDG_UNLIKELY()` |
| Memory sizes | `LDG_KIB`, `LDG_MIB`, `LDG_GIB` |
| Time | `LDG_MS_PER_SEC`, `LDG_NS_PER_MS`, `LDG_NS_PER_SEC`, `LDG_SECS_PER_MIN`, `LDG_SECS_PER_HOUR` |
| Numeric bases | `LDG_BASE_DECIMAL`, `LDG_BASE_HEX` |
| Byte/bit | `LDG_BYTE_BITS`, `LDG_BYTE_MASK`, `LDG_BYTE_SHIFT_*`, `LDG_NIBBLE_BITS`, `LDG_NIBBLE_MASK`, `LDG_WORD_BYTES`, `LDG_IS_POW2()` |
| String | `LDG_STR_TERM`, `LDG_STR_TERM_SIZE` |
| Initialization | `LDG_STRUCT_ZERO_INIT`, `LDG_ARR_ZERO_INIT` |
| Alignment | `LDG_CACHE_LINE_WIDTH`, `LDG_ALIGNED`, `LDG_ALIGNED_UP()`, `LDG_ALIGNED_DOWN()` |

### 10.2 Error Codes (`core/err.h`)

| Range | Category |
|-------|----------|
| 0 | `LDG_ERR_AOK` |
| 1-99 | Generic: `LDG_ERR_FUNC_ARG_NULL`, `LDG_ERR_FUNC_ARG_INVALID`, `LDG_ERR_ALLOC_NULL`, `LDG_ERR_NOT_INIT`, `LDG_ERR_FULL`, `LDG_ERR_OVERFLOW`, `LDG_ERR_EMPTY`, `LDG_ERR_BUSY`, `LDG_ERR_INVALID`, `LDG_ERR_TIMEOUT` |
| 100-199 | Memory: `LDG_ERR_MEM_BAD`, `LDG_ERR_MEM_STR_TRUNC`, `LDG_ERR_MEM_MEMMOVE_ALLOCD`, `LDG_ERR_MEM_SENTINEL`, `LDG_ERR_MEM_POOL_*` |
| 200-299 | I/O: `LDG_ERR_IO_NOT_FOUND`, `LDG_ERR_IO_READ`, `LDG_ERR_IO_WRITE`, `LDG_ERR_IO_FORMAT` |
| 300-399 | Time: `LDG_ERR_TIME_CORE_MIGRATED`, `LDG_ERR_TIME_NOT_CALIBRATED` |
| 400-499 | Network: `LDG_ERR_NET_INIT`, `LDG_ERR_NET_PERFORM`, `LDG_ERR_NET_TIMEOUT`, `LDG_ERR_NET_CONN` |
| 500-599 | String: `LDG_ERR_STR_TRUNC`, `LDG_ERR_STR_OVERLAP` |

Error logging macros: `LDG_ERRLOG_ERR()`, `LDG_ERRLOG_WARN()`, `LDG_ERRLOG_INFO()`

### 10.3 Types (`core/types.h`)

`ldg_byte_t`, `ldg_word_t`, `ldg_dword_t`, `ldg_qword_t`

Non-prefixed aliases: `byte_t`, `word_t`, `dword_t`, `qword_t`

### 10.4 Memory (`mem/`)

| Header | Functions |
|--------|-----------|
| `mem.h` | `ldg_mem_init()`, `ldg_mem_shutdown()`, `ldg_mem_alloc()`, `ldg_mem_realloc()`, `ldg_mem_dealloc()`, `ldg_mem_stats_get()`, `ldg_mem_leaks_dump()`, `ldg_mem_valid_is()`, `ldg_mem_size_get()` |
| `alloc.h` | `ldg_mem_pool_create()`, `ldg_mem_pool_destroy()`, `ldg_mem_pool_alloc()`, `ldg_mem_pool_dealloc()` |
| `secure.h` | `ldg_mem_secure_zero()`, `ldg_mem_secure_copy()`, `ldg_mem_secure_cmp()`, `ldg_mem_secure_cmov()`, `ldg_mem_secure_neq()` |

### 10.5 String (`str/str.h`)

`ldg_strrbrcpy()`, `ldg_str_to_dec()`, `ldg_hex_str_is()`, `ldg_hex_to_bytes()`, `ldg_hex_to_dword()`, `ldg_byte_to_hex()`, `ldg_dword_to_hex()`, `ldg_char_*_is()` predicates

### 10.6 Time (`time/`)

| Header | Functions |
|--------|-----------|
| `time.h` | `ldg_time_init()`, `ldg_time_tick()`, `ldg_time_get()`, `ldg_time_monotonic_get()`, `ldg_time_epoch_ms_get()`, `ldg_time_epoch_ns_get()`, `ldg_time_dt_get()`, `ldg_time_dt_smoothed_get()`, `ldg_time_fps_get()`, `ldg_time_frame_cunt_get()` |
| `perf.h` | High-resolution performance timing |

### 10.7 Threading (`thread/`)

| Header | Functions/Types |
|--------|-----------------|
| `sync.h` | `ldg_mut_t`, `ldg_mut_init()`, `ldg_mut_lock()`, `ldg_mut_unlock()`, `ldg_mut_trylock()`, `ldg_mut_destroy()`; `ldg_cond_t`, `ldg_cond_init()`, `ldg_cond_wait()`, `ldg_cond_timedwait()`, `ldg_cond_signal()`, `ldg_cond_broadcast()`, `ldg_cond_destroy()`; `ldg_sem_t`, `ldg_sem_init()`, `ldg_sem_open()`, `ldg_sem_wait()`, `ldg_sem_trywait()`, `ldg_sem_post()`, `ldg_sem_destroy()` |
| `spsc.h` | `ldg_spsc_queue_t`, `ldg_spsc_init()`, `ldg_spsc_push()`, `ldg_spsc_pop()`, `ldg_spsc_peek()`, `ldg_spsc_cunt()`, `ldg_spsc_empty()`, `ldg_spsc_full()`, `ldg_spsc_shutdown()` |
| `pool.h` | `ldg_thread_pool_t`, `ldg_thread_pool_init()`, `ldg_thread_pool_start()`, `ldg_thread_pool_stop()`, `ldg_thread_pool_shutdown()`, `ldg_thread_pool_worker_cunt_get()` |

### 10.8 Math (`math/linalg.h`)

`ldg_vec3_*()`, `ldg_mat3_*()` (add, sub, scale, dot, cross, mul, inv, det, trace, transpose, etc.)

### 10.9 Network (`net/curl.h`)

`ldg_curl_multi_ctx_t`, `ldg_curl_multi_ctx_create()`, `ldg_curl_multi_req_add()`, `ldg_curl_multi_perform()`, `ldg_curl_multi_progress_get()`, `ldg_curl_multi_ctx_destroy()`, `ldg_curl_resp_t`

### 10.10 Parsing (`parse/parse.h`)

`ldg_tok_t`, `ldg_tok_arr_t`, `ldg_parse_tokenize()`, `ldg_parse_streq()`

### 10.11 x86-64 Architecture (`arch/x86_64/`)

| Header | Macros/Functions |
|--------|------------------|
| `fence.h` | `LDG_MFENCE`, `LDG_SFENCE`, `LDG_LFENCE`, `LDG_BARRIER`, `LDG_PAUSE`, `LDG_SMP_MB()`, `LDG_SMP_WMB()`, `LDG_SMP_RMB()`, `LDG_SMP_SIG_FENCE()` |
| `atomic.h` | `LDG_READ_ONCE()`, `LDG_WRITE_ONCE()`, `LDG_READ_ONCE_AGGREGATE()`, `LDG_WRITE_ONCE_AGGREGATE()`, `LDG_LOAD_ACQUIRE()`, `LDG_STORE_RELEASE()`, `LDG_FETCH_ADD()`, `LDG_FETCH_SUB()`, `LDG_ADD_FETCH()`, `LDG_SUB_FETCH()`, `LDG_CAS()`, `LDG_CAS_WEAK()` |
| `prefetch.h` | `LDG_PREFETCH_R()`, `LDG_PREFETCH_W()`, `LDG_PREFETCH_NTA()` |
| `tsc.h` | `ldg_tsc_ctx_t`, `ldg_rdtsc()`, `ldg_rdtscp()`, `ldg_tsc_calibrate()`, `ldg_tsc_sample()`, `ldg_tsc_serialized_sample()`, `ldg_tsc_serialize()`, `ldg_tsc_delta()`, `ldg_tsc_to_sec()` |
| `cpuid.h` | `ldg_cpuid()`, `ldg_cpuid_features_t`, `ldg_cpuid_features_get()`, `ldg_cpuid_vendor_get()`, `ldg_cpuid_brand_get()`, `ldg_cpu_core_id_get()`, `ldg_cpu_relax()` |
| `syscall.h` | `ldg_syscall0()` through `ldg_syscall4()`, `LDG_SYS_*` constants |

---

## Appendix A: Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-23 | Initial specification |
