# Slash Rush 노말 플레이 스폰 시스템 리팩토링 개발지시서

## 0. 목적

현재 Slash Rush에는 오브젝트가 무작정 랜덤 스폰되는 코드가 있다. 이 방식은 난이도 조절이 어렵고, `coin`, `fever_orb`, `heal` 같은 먹는 아이템이 과하게 나오거나 연속 등장할 수 있어 게임 밸런스가 쉽게 무너진다.

이번 작업의 목표는 기존 랜덤 스폰 방식을 정리하고, 60초 노말 플레이 기준으로 **규칙 기반 스폰 스케줄 시스템**을 구현하는 것이다.

핵심 방향은 다음과 같다.

```text
1. 게임 시작 시 60초짜리 노말 스폰 일정표만 미리 생성한다.
2. 실제 Node는 해당 시간이 되었을 때만 생성한다.
3. 피버는 노말 스폰 일정표와 완전히 분리된 별도 스포너로 처리한다.
4. coin / fever_orb / heal은 몬스터 랜덤 풀에 넣지 않고, 별도의 아이템 예산과 규칙으로 관리한다.
5. heal은 체력이 3이면 스폰되지 않는 조건부 후보 아이템으로 관리한다.
6. 모든 밸런스 수치는 한 곳에서 쉽게 수정할 수 있도록 분리한다.
7. 기존 무작정 랜덤 스폰 코드는 개발 완료 후 제거하거나 비활성화한다.
```

---

## 1. 중요한 전제

### 1-1. 노말 플레이 시간

노말 플레이는 60초 고정으로 처리한다.

기존처럼 “몇 번째 오브젝트가 나왔는지”로 스테이지 길이를 결정하지 않는다.

```text
나쁜 방식:
28번째 오브젝트가 스폰되면 다음 단계로 이동

좋은 방식:
stage_time이 60초에 도달하면 노말 플레이 종료
```

### 1-2. 게임 내 튜토리얼 없음

현재 게임에는 별도 타격 연습이나 멈춰서 설명하는 튜토리얼을 구현하지 않는다.  
대신 HOW TO 카드에서 규칙을 먼저 설명하고, 게임은 바로 실전으로 들어간다.

다만 첫 8초는 튜토리얼이 아니라 **낮은 밀도의 실전 완충 구간**으로 구성한다.

### 1-3. 피버는 노말 스케줄을 소모하지 않음

피버 중에는 몬스터가 무더기로 나오지만, 이것이 노말 스폰 스케줄을 소비하면 안 된다.

피버 중에는 다음처럼 처리한다.

```text
피버 시작
→ 노말 스폰 잠시 비활성화
→ 화면에 남아 있는 기존 노말 오브젝트 정리
→ FeverSpawner가 별도 규칙으로 몬스터 무더기 생성
→ 피버 중 지나간 노말 이벤트는 스폰하지 않고 스킵
→ 피버 종료 후 0.5~1초 완충
→ 현재 stage_time 기준으로 노말 스케줄 복귀
```

---

## 2. 생성/수정할 파일 구조 제안

프로젝트 구조에 맞게 경로는 조정 가능하지만, 역할은 반드시 분리한다.

권장 경로:

```text
res://scripts/spawn/
  SpawnBalance.gd
  StageSpawnDirector.gd
  NormalScheduleGenerator.gd
  ItemSpawnRules.gd
  FeverSpawner.gd
  SpawnEvent.gd
```

역할:

```text
SpawnBalance.gd
- 모든 스폰/난이도/아이템/피버 수치를 한 곳에서 관리

StageSpawnDirector.gd
- 실제 게임 진행 중 stage_time을 기준으로 스폰 실행
- NormalScheduleGenerator가 만든 스케줄을 읽어서 오브젝트 생성
- 피버 시작/종료 시 Normal/Fever 전환 담당
- 기존 랜덤 스폰 코드를 대체하는 중심 컨트롤러

NormalScheduleGenerator.gd
- 게임 시작 전에 60초짜리 노말 스폰 일정표 생성
- 위험 오브젝트와 아이템 후보 슬롯을 구간별 규칙에 따라 배치

ItemSpawnRules.gd
- coin / fever_orb / heal 스폰 가능 여부 판단
- heal_candidate를 실제 heal로 바꿀지 판단
- 아이템 개수 제한, 연속 등장 제한, 쿨타임 관리

FeverSpawner.gd
- 피버 중 별도 몬스터 무더기 스폰
- 노말 스케줄과 독립적으로 동작

SpawnEvent.gd
- 스폰 이벤트 데이터 구조
```

기존 프로젝트가 작은 구조라면 파일 수를 줄여도 된다.  
그러나 최소한 아래 3개 역할은 반드시 분리한다.

```text
1. 밸런스 수치 파일
2. 노말 스폰 스케줄 생성 파일
3. 실제 스폰 실행/피버 전환 파일
```

---

## 3. SpawnBalance.gd 작성 지시

모든 밸런스 수치는 이 파일에서 관리한다.  
게임 밸런스를 바꿀 때 여러 파일을 뒤지지 않도록 한다.

예시:

```gdscript
# res://scripts/spawn/SpawnBalance.gd
extends RefCounted
class_name SpawnBalance

const STAGE_DURATION := 60.0

# 구간 정의
const PHASES := [
    {
        "name": "opening_buffer",
        "start": 0.0,
        "end": 8.0,
        "spawn_interval_min": 0.9,
        "spawn_interval_max": 1.2,
        "allowed_danger": ["enemy_basic", "bomb"],
        "allow_fast": false,
        "allow_armor": false
    },
    {
        "name": "basic_mix",
        "start": 8.0,
        "end": 18.0,
        "spawn_interval_min": 0.75,
        "spawn_interval_max": 1.0,
        "allowed_danger": ["enemy_basic", "bomb", "enemy_fast"],
        "allow_fast": true,
        "allow_armor": false
    },
    {
        "name": "input_pressure",
        "start": 18.0,
        "end": 30.0,
        "spawn_interval_min": 0.65,
        "spawn_interval_max": 0.9,
        "allowed_danger": ["enemy_basic", "bomb", "enemy_fast"],
        "allow_fast": true,
        "allow_armor": false
    },
    {
        "name": "armor_mix",
        "start": 30.0,
        "end": 42.0,
        "spawn_interval_min": 0.7,
        "spawn_interval_max": 1.0,
        "allowed_danger": ["enemy_basic", "bomb", "enemy_fast", "enemy_armor"],
        "allow_fast": true,
        "allow_armor": true
    },
    {
        "name": "high_pressure",
        "start": 42.0,
        "end": 52.0,
        "spawn_interval_min": 0.55,
        "spawn_interval_max": 0.8,
        "allowed_danger": ["enemy_basic", "bomb", "enemy_fast", "enemy_armor"],
        "allow_fast": true,
        "allow_armor": true
    },
    {
        "name": "final_wave",
        "start": 52.0,
        "end": 60.0,
        "spawn_interval_min": 0.5,
        "spawn_interval_max": 0.75,
        "allowed_danger": ["enemy_basic", "bomb", "enemy_fast", "enemy_armor"],
        "allow_fast": true,
        "allow_armor": true
    }
]

# 아이템 예산
const ITEM_BUDGET := {
    "coin": 14,
    "fever_orb": 2,
    "heal": 2
}

# 아이템 간격 규칙
const GOOD_ITEM_MIN_INTERVAL := 2.0
const HEAL_MIN_INTERVAL := 12.0
const FEVER_ORB_MIN_INTERVAL := 16.0
const FEVER_AFTER_END_BLOCK_TIME := 8.0

# heal 조건
const HEAL_CANDIDATE_TIMES := [24.0, 42.0, 54.0]

# fever_orb 후보 시간대
const FEVER_ORB_WINDOWS := [
    { "start": 18.0, "end": 26.0 },
    { "start": 42.0, "end": 52.0 }
]

# coin 후보 수량
const COIN_TARGET_MIN := 10
const COIN_TARGET_MAX := 14

# armor 안전 간격
const ARMOR_MIN_GAP_BEFORE := 0.85
const ARMOR_MIN_GAP_AFTER := 0.85

# fast 뒤 아이템 최소 간격
const ITEM_AFTER_FAST_MIN_GAP := 0.65

# 피버
const FEVER_DURATION := 5.5
const FEVER_SPAWN_INTERVAL_MIN := 0.12
const FEVER_SPAWN_INTERVAL_MAX := 0.22
const FEVER_RECOVER_TIME := 0.8

# 피버 중 오브젝트 가중치
const FEVER_OBJECT_WEIGHTS := {
    "enemy_basic": 75,
    "enemy_fast": 15,
    "bomb": 10
}
```

주의:

- 숫자는 초기값이다. 실제 플레이 테스트 후 조정 가능해야 한다.
- `enemy_armor`는 피버 중에는 스폰하지 않는다.
- `heal`은 일반 스폰 이벤트가 아니라 `heal_candidate`로 먼저 배치한다.

---

## 4. SpawnEvent.gd 작성 지시

스폰 이벤트는 실제 Node가 아니라 데이터다.

```gdscript
# res://scripts/spawn/SpawnEvent.gd
extends RefCounted
class_name SpawnEvent

var time: float
var type: String
var lane: int = 0
var meta: Dictionary = {}

func _init(_time: float, _type: String, _lane: int = 0, _meta: Dictionary = {}):
    time = _time
    type = _type
    lane = _lane
    meta = _meta
```

`type` 예시:

```text
enemy_basic
enemy_fast
enemy_armor
bomb
coin
fever_orb
heal_candidate
```

`heal_candidate`는 실제 스폰 시점에 `heal`이 될 수도 있고, 아무것도 스폰되지 않을 수도 있다.

---

## 5. NormalScheduleGenerator.gd 작성 지시

이 파일은 게임 시작 전에 60초짜리 노말 스폰 스케줄을 생성한다.

주의: 실제 Node를 만들지 않는다.  
오직 `SpawnEvent` 배열만 만든다.

### 5-1. 기본 구조

```gdscript
# res://scripts/spawn/NormalScheduleGenerator.gd
extends RefCounted
class_name NormalScheduleGenerator

func generate(seed_value: int = 0) -> Array:
    if seed_value != 0:
        seed(seed_value)

    var events: Array = []

    _generate_danger_events(events)
    _insert_item_candidates(events)

    events.sort_custom(func(a, b): return a.time < b.time)
    return events
```

---

### 5-2. 위험 오브젝트 생성

위험 오브젝트는 아래 타입을 의미한다.

```text
enemy_basic
enemy_fast
enemy_armor
bomb
```

구간별로 spawn interval을 다르게 적용한다.

```gdscript
func _generate_danger_events(events: Array) -> void:
    for phase in SpawnBalance.PHASES:
        var t: float = phase["start"]

        while t < phase["end"]:
            var interval = randf_range(
                phase["spawn_interval_min"],
                phase["spawn_interval_max"]
            )
            t += interval

            if t >= phase["end"]:
                break

            var object_type = _pick_danger_type(phase, t, events)

            if object_type == "":
                continue

            events.append(SpawnEvent.new(t, object_type))
```

---

### 5-3. 위험 오브젝트 선택 규칙

단순 랜덤이 아니라 이전 이벤트와의 관계를 고려한다.

규칙:

```text
1. opening_buffer 구간에서는 enemy_armor 금지
2. 30초 전에는 enemy_armor 금지
3. enemy_armor는 앞뒤 간격을 넓게 확보
4. enemy_fast가 너무 연속으로 나오지 않게 제한
5. bomb이 3회 이상 연속으로 나오지 않게 제한
6. 좋은 아이템은 여기서 뽑지 않는다
```

예시:

```gdscript
func _pick_danger_type(phase: Dictionary, t: float, events: Array) -> String:
    var allowed: Array = phase["allowed_danger"].duplicate()

    if t < 30.0:
        allowed.erase("enemy_armor")

    if not _can_place_armor_at(t, events):
        allowed.erase("enemy_armor")

    if _was_recent_type(events, "enemy_fast", 1):
        allowed.erase("enemy_fast")

    if _was_recent_type(events, "bomb", 2):
        allowed.erase("bomb")

    if allowed.is_empty():
        return "enemy_basic"

    return allowed[randi() % allowed.size()]
```

---

### 5-4. 아이템 후보 삽입

아이템은 위험 오브젝트 생성 후, 안전한 시간대에 삽입한다.

아이템 타입:

```text
coin
fever_orb
heal_candidate
```

규칙:

```text
coin:
- 60초 기준 10~14개
- 좋은 아이템끼리 최소 2초 간격
- enemy_fast 직후 너무 가까이 배치 금지
- enemy_armor 직전/직후 너무 가까이 배치 금지

fever_orb:
- 60초 기준 최대 2개
- 18~26초 후보 1개
- 42~52초 후보 1개
- 좋은 아이템 간격 규칙 준수

heal_candidate:
- 24초, 42초, 54초 근처 후보
- 실제 heal 스폰 여부는 게임 중 ItemSpawnRules가 결정
```

아이템 후보 삽입 예시:

```gdscript
func _insert_item_candidates(events: Array) -> void:
    _insert_fever_orb_candidates(events)
    _insert_heal_candidates(events)
    _insert_coin_candidates(events)
```

---

### 5-5. 안전 슬롯 검색

아무 시간에 아이템을 넣지 말고, 위험 오브젝트 사이 여유가 있는 곳에 넣는다.

```gdscript
func _is_safe_item_time(t: float, events: Array) -> bool:
    for e in events:
        var gap = abs(e.time - t)

        if gap < SpawnBalance.GOOD_ITEM_MIN_INTERVAL and _is_good_item_type(e.type):
            return false

        if e.type == "enemy_fast" and e.time < t and t - e.time < SpawnBalance.ITEM_AFTER_FAST_MIN_GAP:
            return false

        if e.type == "enemy_armor" and gap < SpawnBalance.ARMOR_MIN_GAP_BEFORE:
            return false

    return true
```

---

## 6. ItemSpawnRules.gd 작성 지시

아이템 스폰 가능 여부는 이 파일에서 판단한다.

특히 `heal`은 현재 체력 상태를 봐야 하므로 스케줄 생성 시점이 아니라 실제 스폰 시점에 판단한다.

### 6-1. 관리 상태

```gdscript
# res://scripts/spawn/ItemSpawnRules.gd
extends RefCounted
class_name ItemSpawnRules

var item_budget := {}
var item_spawned_count := {}

var last_good_item_time := -999.0
var last_heal_time := -999.0
var last_fever_orb_time := -999.0

func _init():
    item_budget = SpawnBalance.ITEM_BUDGET.duplicate()
    item_spawned_count = {
        "coin": 0,
        "fever_orb": 0,
        "heal": 0
    }
```

---

### 6-2. 좋은 아이템 공통 검사

```gdscript
func can_spawn_good_item(type: String, stage_time: float, fever_active: bool) -> bool:
    if fever_active:
        return false

    if not item_budget.has(type):
        return false

    if item_spawned_count[type] >= item_budget[type]:
        return false

    if stage_time - last_good_item_time < SpawnBalance.GOOD_ITEM_MIN_INTERVAL:
        return false

    return true
```

---

### 6-3. coin 검사

```gdscript
func can_spawn_coin(stage_time: float, fever_active: bool) -> bool:
    return can_spawn_good_item("coin", stage_time, fever_active)
```

---

### 6-4. fever_orb 검사

```gdscript
func can_spawn_fever_orb(stage_time: float, fever_active: bool, last_fever_end_time: float) -> bool:
    if not can_spawn_good_item("fever_orb", stage_time, fever_active):
        return false

    if stage_time - last_fever_orb_time < SpawnBalance.FEVER_ORB_MIN_INTERVAL:
        return false

    if stage_time - last_fever_end_time < SpawnBalance.FEVER_AFTER_END_BLOCK_TIME:
        return false

    return true
```

---

### 6-5. heal 검사

```gdscript
func can_spawn_heal(stage_time: float, fever_active: bool, player_hp: int, player_max_hp: int) -> bool:
    if fever_active:
        return false

    if player_hp >= player_max_hp:
        return false

    if item_spawned_count["heal"] >= item_budget["heal"]:
        return false

    if stage_time - last_heal_time < SpawnBalance.HEAL_MIN_INTERVAL:
        return false

    if stage_time - last_good_item_time < SpawnBalance.GOOD_ITEM_MIN_INTERVAL:
        return false

    return true
```

---

### 6-6. 스폰 기록

실제 스폰에 성공했을 때만 기록한다.

```gdscript
func mark_spawned(type: String, stage_time: float) -> void:
    if not item_spawned_count.has(type):
        return

    item_spawned_count[type] += 1
    last_good_item_time = stage_time

    if type == "heal":
        last_heal_time = stage_time

    if type == "fever_orb":
        last_fever_orb_time = stage_time
```

주의:

- `heal_candidate`가 조건 미달로 실제 스폰되지 않았다면 `mark_spawned("heal")`을 호출하지 않는다.
- 체력이 3일 때 heal_candidate는 그냥 무시한다.
- heal_candidate를 coin으로 대체하지 않는다. MVP에서는 아무것도 스폰하지 않는 쪽이 더 안전하다.

---

## 7. FeverSpawner.gd 작성 지시

피버 중에는 노말 스케줄과 별개로 몬스터를 빠르게 스폰한다.

### 7-1. 기본 구조

```gdscript
# res://scripts/spawn/FeverSpawner.gd
extends RefCounted
class_name FeverSpawner

var spawn_timer := 0.0

func reset() -> void:
    spawn_timer = 0.0

func update(delta: float, spawn_callback: Callable) -> void:
    spawn_timer -= delta

    if spawn_timer <= 0.0:
        var object_type = _pick_fever_object()
        spawn_callback.call(object_type)
        spawn_timer = randf_range(
            SpawnBalance.FEVER_SPAWN_INTERVAL_MIN,
            SpawnBalance.FEVER_SPAWN_INTERVAL_MAX
        )
```

---

### 7-2. 피버 오브젝트 선택

```gdscript
func _pick_fever_object() -> String:
    var weights = SpawnBalance.FEVER_OBJECT_WEIGHTS
    var total := 0

    for value in weights.values():
        total += int(value)

    var roll := randi() % total
    var acc := 0

    for key in weights.keys():
        acc += int(weights[key])
        if roll < acc:
            return key

    return "enemy_basic"
```

피버 중에는 다음 아이템/몬스터를 제외한다.

```text
제외:
- coin
- heal
- fever_orb
- enemy_armor
```

이유:

- 피버는 보상 타임이자 광속 칼질 타임이다.
- coin/heal/fever_orb가 나오면 규칙이 흐려진다.
- enemy_armor는 롱클릭을 요구해 피버 리듬을 망친다.

---

## 8. StageSpawnDirector.gd 작성 지시

이 파일이 실제 게임 진행 중 스폰을 관리한다.

### 8-1. 주요 상태

```gdscript
# res://scripts/spawn/StageSpawnDirector.gd
extends Node
class_name StageSpawnDirector

var stage_time := 0.0
var normal_schedule: Array = []
var normal_index := 0

var item_rules: ItemSpawnRules
var fever_spawner: FeverSpawner

var fever_active := false
var fever_time_left := 0.0
var fever_recover_time := 0.0
var last_fever_end_time := -999.0

@export var player_path: NodePath
@onready var player = get_node(player_path)
```

실제 프로젝트 구조에 따라 player 접근 방식은 수정 가능하다.

---

### 8-2. 시작 시 스케줄 생성

```gdscript
func _ready():
    item_rules = ItemSpawnRules.new()
    fever_spawner = FeverSpawner.new()

    var generator = NormalScheduleGenerator.new()
    normal_schedule = generator.generate()
    normal_index = 0
```

---

### 8-3. process 흐름

```gdscript
func _process(delta: float) -> void:
    stage_time += delta

    if stage_time >= SpawnBalance.STAGE_DURATION:
        _end_normal_stage()
        return

    if fever_active:
        _update_fever(delta)
        return

    if fever_recover_time > 0.0:
        fever_recover_time -= delta
        _skip_normal_events_until(stage_time)
        return

    _update_normal_spawns()
```

---

### 8-4. 노말 스폰 처리

```gdscript
func _update_normal_spawns() -> void:
    while normal_index < normal_schedule.size():
        var event: SpawnEvent = normal_schedule[normal_index]

        if event.time <= stage_time:
            _handle_spawn_event(event)
            normal_index += 1
        else:
            break
```

---

### 8-5. 이벤트 타입별 처리

```gdscript
func _handle_spawn_event(event: SpawnEvent) -> void:
    match event.type:
        "coin":
            if item_rules.can_spawn_coin(stage_time, fever_active):
                _spawn_object("coin")
                item_rules.mark_spawned("coin", stage_time)

        "fever_orb":
            if item_rules.can_spawn_fever_orb(stage_time, fever_active, last_fever_end_time):
                _spawn_object("fever_orb")
                item_rules.mark_spawned("fever_orb", stage_time)

        "heal_candidate":
            if item_rules.can_spawn_heal(stage_time, fever_active, player.hp, player.max_hp):
                _spawn_object("heal")
                item_rules.mark_spawned("heal", stage_time)

        _:
            _spawn_object(event.type)
```

주의:

- `player.hp`, `player.max_hp`는 실제 프로젝트의 변수명에 맞게 수정한다.
- 현재 생명력 max는 3이다.
- `heal`을 먹었을 때 이미 3이면 + 되지 않는 기존 규칙은 유지한다.
- 하지만 스폰 단계에서 애초에 체력 3이면 heal을 안 나오게 하는 것이 목표다.

---

### 8-6. 피버 시작

`fever_orb`를 플레이어가 정상 획득했을 때 아래 함수를 호출하도록 연결한다.

```gdscript
func start_fever() -> void:
    if fever_active:
        return

    fever_active = true
    fever_time_left = SpawnBalance.FEVER_DURATION
    fever_spawner.reset()

    _clear_active_normal_objects()
    _show_fever_start_effect()
```

피버 시작 시 기존 화면 오브젝트는 정리한다.

```gdscript
func _clear_active_normal_objects() -> void:
    # 현재 스폰되어 화면에 남아 있는 노말 오브젝트들을 제거한다.
    # 프로젝트 구조에 맞게 group을 사용하는 것을 추천한다.
    # 예: 모든 스폰 오브젝트에 "spawned_object" group 추가
    get_tree().call_group("spawned_object", "queue_free")
```

권장:

- 스폰되는 모든 오브젝트에 `spawned_object` group을 추가한다.
- 피버 중 생성되는 오브젝트도 같은 group이어도 되지만, 피버 시작 시점에만 정리하면 된다.

---

### 8-7. 피버 업데이트

```gdscript
func _update_fever(delta: float) -> void:
    fever_time_left -= delta

    fever_spawner.update(delta, Callable(self, "_spawn_object"))

    _skip_normal_events_until(stage_time)

    if fever_time_left <= 0.0:
        _end_fever()
```

---

### 8-8. 피버 종료

```gdscript
func _end_fever() -> void:
    fever_active = false
    last_fever_end_time = stage_time
    fever_recover_time = SpawnBalance.FEVER_RECOVER_TIME
    _show_fever_end_effect()
```

---

### 8-9. 피버 중 지나간 노말 이벤트 스킵

```gdscript
func _skip_normal_events_until(current_time: float) -> void:
    while normal_index < normal_schedule.size():
        var event: SpawnEvent = normal_schedule[normal_index]

        if event.time <= current_time:
            normal_index += 1
        else:
            break
```

이 함수는 피버 중 또는 피버 종료 직후 완충 시간에 호출한다.  
노말 스케줄을 멈추지 않고, 60초 고정 흐름을 유지하기 위해 지나간 이벤트는 버린다.

---

### 8-10. 실제 오브젝트 생성 함수

기존 프로젝트에 이미 오브젝트 생성 함수가 있을 가능성이 높다.  
기존 함수를 재사용하되, 랜덤 선택 책임은 제거한다.

```gdscript
func _spawn_object(type: String) -> void:
    # type에 따라 PackedScene을 찾아 instantiate
    # 기존 spawn 코드가 있다면 여기로 옮기거나 래핑한다.
    #
    # 예:
    # var scene = spawn_scene_map[type]
    # var obj = scene.instantiate()
    # obj.add_to_group("spawned_object")
    # spawn_parent.add_child(obj)
    # obj.global_position = _get_spawn_position()
    pass
```

중요:

- `_spawn_object()`는 타입을 받아 실제 생성만 담당한다.
- 이 함수 안에서 다시 랜덤으로 타입을 뽑으면 안 된다.
- 타입 선택은 `NormalScheduleGenerator`, `FeverSpawner`, `ItemSpawnRules` 쪽에서 이미 끝나야 한다.

---

## 9. 기존 랜덤 스폰 코드 정리 지시

기존에 무작정 랜덤으로 스폰하는 코드가 있다면 다음 순서로 정리한다.

### 9-1. 기존 코드에서 보존할 것

보존할 가능성이 높은 기능:

```text
- PackedScene 참조
- 실제 instantiate 로직
- spawn 위치 계산
- 오브젝트 parent에 add_child 하는 코드
- 오브젝트 초기 속도/이동 방향 설정
- 스폰 이펙트
```

이 부분은 `_spawn_object(type)` 내부로 옮겨 재사용한다.

### 9-2. 제거하거나 비활성화할 것

제거할 기능:

```text
- 일정 시간마다 랜덤 타입 선택
- coin/heal/fever_orb를 몬스터와 같은 랜덤 풀에서 선택
- 랜덤으로 heal을 스폰하는 코드
- 피버 중 노말 스폰 배열을 그대로 소비하는 코드
- 오브젝트 개수 기준으로 스테이지 종료하는 코드
```

### 9-3. 임시 안전장치

기존 코드 삭제가 부담되면 우선 플래그로 막는다.

```gdscript
const USE_NEW_SPAWN_DIRECTOR := true
```

단, 최종적으로는 중복 스폰이 발생하지 않도록 기존 랜덤 스폰 루프를 제거해야 한다.

---

## 10. 오브젝트 타입별 규칙 정리

### enemy_basic

```text
- 일반 탭 1회로 처리
- 모든 구간 등장 가능
- 가장 기본이 되는 위험 오브젝트
```

### enemy_fast

```text
- 더블탭으로 처리
- 8초 이후부터 등장 가능
- 연속 등장 제한
- 직후에 coin/heal을 너무 가깝게 배치하지 않음
```

### enemy_armor

```text
- 롱클릭으로 처리
- 30초 이후부터 등장
- 피버 중 등장 금지
- 앞뒤 최소 간격 필요
```

### bomb

```text
- 썩은사과 역할
- 먹으면 피해 또는 독
- 베어야 안전
- heal/coin과 헷갈림을 만드는 핵심 오브젝트
```

### coin

```text
- 먹어야 획득
- 베면 파괴
- 60초 기준 10~14개
- 연속 등장 금지
```

### fever_orb

```text
- 먹으면 피버 발동
- 베면 손실
- 60초 기준 최대 2개
- 피버 중 스폰 금지
```

### heal

```text
- 먹으면 체력 회복
- 체력 max는 3
- 체력이 3이면 스폰하지 않음
- 60초 기준 실제 등장 최대 2개
- heal_candidate로만 관리
```

---

## 11. 추천 60초 흐름

아래는 고정 스크립트가 아니라 목표 리듬이다.

```text
0~8초:
- 낮은 밀도 실전 완충
- enemy_basic, bomb, coin 중심
- enemy_armor 금지

8~18초:
- enemy_fast 등장 시작
- coin과 bomb을 섞어 먹기/베기 판단 유도

18~30초:
- fever_orb 후보 1회
- heal_candidate 1회
- enemy_basic, enemy_fast, bomb 혼합

30~42초:
- enemy_armor 첫 등장
- armor 앞뒤 간격 넓게
- coin/heal_candidate를 적절히 배치

42~52초:
- 고밀도 압박
- fever_orb 후보 1회
- fast/bomb/armor 혼합

52~60초:
- 마무리 웨이브
- 압박 후 보상성 coin 또는 heal_candidate 가능
```

---

## 12. 디버그 기능 추가 권장

밸런스 조정을 쉽게 하기 위해 디버그 출력 기능을 추가한다.

```gdscript
func debug_print_schedule() -> void:
    for event in normal_schedule:
        print("[SPAWN] ", event.time, " / ", event.type)
```

추가로 개발 중에는 화면 좌상단 또는 콘솔에 아래 정보를 볼 수 있으면 좋다.

```text
stage_time
normal_index / normal_schedule.size()
fever_active
fever_time_left
coin spawned count
fever_orb spawned count
heal spawned count
player hp
```

디버그 UI 구현이 부담되면 우선 콘솔 출력만 해도 된다.

---

## 13. 테스트 체크리스트

개발 완료 후 아래 항목을 확인한다.

### 기본 스폰

```text
[ ] 60초 기준으로 노말 스폰이 진행된다.
[ ] 실제 Node는 시작 시 전부 생성되지 않고, 해당 시간이 되었을 때 생성된다.
[ ] 기존 랜덤 스폰 루프와 중복으로 스폰되지 않는다.
[ ] stage_time 60초 도달 시 정상 종료 또는 다음 단계로 이동한다.
```

### 아이템

```text
[ ] coin이 연속으로 나오지 않는다.
[ ] coin / heal / fever_orb 같은 좋은 아이템이 연속으로 나오지 않는다.
[ ] fever_orb는 최대 2개까지만 등장한다.
[ ] heal은 체력이 3이면 등장하지 않는다.
[ ] heal은 실제 등장 최대 2개를 넘지 않는다.
[ ] heal_candidate가 조건 불만족일 때 coin으로 대체되지 않는다.
```

### 피버

```text
[ ] fever_orb를 먹으면 피버가 시작된다.
[ ] 피버 시작 시 기존 화면 오브젝트가 정리된다.
[ ] 피버 중에는 노말 스폰이 나오지 않는다.
[ ] 피버 중에는 FeverSpawner가 별도 몬스터를 빠르게 스폰한다.
[ ] 피버 중 enemy_armor, coin, heal, fever_orb가 나오지 않는다.
[ ] 피버 종료 후 0.5~1초 완충 후 노말 패턴으로 복귀한다.
[ ] 피버 때문에 전체 플레이 시간이 60초를 초과하지 않는다.
```

### 밸런스 조정

```text
[ ] SpawnBalance.gd만 수정해도 주요 스폰 수치가 조정된다.
[ ] coin 개수, heal 최대 등장 수, fever_orb 최대 등장 수를 쉽게 바꿀 수 있다.
[ ] 피버 지속 시간과 피버 스폰 속도를 쉽게 바꿀 수 있다.
[ ] 구간별 스폰 간격을 쉽게 바꿀 수 있다.
```

---

## 14. 구현 우선순위

한 번에 완벽히 만들려고 하지 말고 아래 순서로 진행한다.

### 1단계

```text
- SpawnBalance.gd 생성
- SpawnEvent.gd 생성
- NormalScheduleGenerator.gd 생성
- 60초 노말 스케줄 생성
- 콘솔에 스케줄 출력
```

### 2단계

```text
- StageSpawnDirector.gd 생성
- 기존 실제 spawn 로직을 _spawn_object(type)로 이동
- 기존 랜덤 타입 선택 제거
- 스케줄 기반 노말 스폰 동작 확인
```

### 3단계

```text
- ItemSpawnRules.gd 생성
- coin / fever_orb / heal_candidate 규칙 적용
- heal은 체력 3이면 스폰되지 않도록 처리
```

### 4단계

```text
- FeverSpawner.gd 생성
- fever_orb 획득 시 start_fever 연결
- 피버 중 노말 스폰 스킵
- 피버 몬스터 무더기 스폰 구현
```

### 5단계

```text
- 기존 랜덤 스폰 코드 제거 또는 완전 비활성화
- 중복 스폰 여부 확인
- SpawnBalance.gd 수치 조정
```

---

## 15. 최종 목표

최종적으로 스폰 시스템은 다음 구조가 되어야 한다.

```text
StageSpawnDirector
 ├─ normal_schedule: SpawnEvent[]
 ├─ NormalScheduleGenerator
 ├─ ItemSpawnRules
 ├─ FeverSpawner
 └─ _spawn_object(type)
```

중요한 설계 원칙:

```text
- 스폰 타입 선택과 실제 Node 생성 책임을 분리한다.
- 밸런스 수치는 SpawnBalance.gd에 모은다.
- 아이템은 몬스터 랜덤 풀에 넣지 않는다.
- heal은 조건부 후보로만 관리한다.
- 피버는 노말 스케줄과 분리한다.
- 기존 랜덤 스폰 루프는 최종적으로 제거한다.
```

이 구조를 지키면 이후에 난이도 조정, 아이템 수량 조정, 피버 지속 시간 조정, 구간별 몬스터 밀도 조정이 쉬워진다.
