# Slash Rush Codex 개발지시서 v0.1

이 문서는 Godot 4.x와 GDScript로 **Slash Rush** 프로토타입을 만들기 위한 Codex 작업 지시서다. 목표는 “러닝 구간 + 베기/참기 판단 + 두동강 물리 연출 + 피버 + 짧은 보스전”이 처음부터 끝까지 플레이 가능한 버전을 만드는 것이다.

---

## 0. 절대 우선순위

1. **모바일 가로모드 게임**으로 만든다. 기본 해상도는 `1280x720`을 기준으로 한다.
2. 모바일 입력은 **화면 탭/롱탭** 중심이다.
3. PC 입력은 개발 편의용이다. 기본 탭은 `Space` 또는 `Mouse Left Button`으로 처리한다.
4. 보조 슬라이스/예비 입력이 필요하면 PC에서는 `Mouse Right Button` 또는 별도 키를 쓰되, MVP에서는 방향 슬라이스를 구현하지 않아도 된다.
5. 캐릭터 이미지는 사용자가 프로젝트 루트에 둘 예정이다. 루트에 이미지가 있으면 `res://assets/characters/` 폴더를 만들고 그쪽으로 옮겨 사용한다.
6. 그 외 이미지는 아직 없으므로 Godot 기본 오브젝트, ColorRect, Polygon2D, Line2D, Label 등으로 플레이 가능한 프로토타입을 만든다.
7. 실시간 이미지 절단 시스템을 만들지 말고, “베는 순간 원본 제거 → 조각 2개 생성 → RigidBody2D 물리로 튀고 회전”하는 방식으로 구현한다.
8. 코드와 씬은 나중에 실제 에셋으로 교체하기 쉽게 구조화한다.

---

## 1. 게임 요약

**제목:** Slash Rush  
**장르:** 2D/2.5D 하이퍼캐주얼 액션 러너  
**핵심 규칙:** 수련 타깃과 위험물은 탭/탭탭/롱탭으로 처리하고, 좋은 아이템은 베지 않고 몸으로 먹는다.  
**게임 흐름:** 타이틀 → 자동 러닝 → 피버 가능 → 보스전 → 결과/재시작

캐릭터는 화면 왼쪽 고정 위치에서 달리는 것처럼 보인다. 실제로는 바닥, 배경, 오브젝트가 왼쪽으로 이동한다. 배경은 여러 레이어가 서로 다른 속도로 움직여 2D 안에서 깊이감을 만든다.

---

## 2. Godot 프로젝트 설정

### 2.1 기본 설정

- Godot 4.x 기준으로 작업한다.
- 렌더러는 2D 프로토타입에 적합한 기본 설정을 사용한다.
- 메인 씬은 `res://scenes/Main.tscn`으로 둔다.
- 해상도 기준:
  - `display/window/size/viewport_width = 1280`
  - `display/window/size/viewport_height = 720`
  - `display/window/stretch/mode = "canvas_items"`
  - `display/window/stretch/aspect = "expand"` 또는 프로젝트 상태상 더 안정적이면 `"keep"` 사용
- 모바일 방향:
  - `display/window/handheld/orientation = DisplayServer.SCREEN_LANDSCAPE`에 해당하는 값으로 설정한다.
  - Godot 4 공식 enum 기준 `SCREEN_LANDSCAPE = 0`이다.

### 2.2 입력 액션

Project Settings > Input Map 또는 코드/프로젝트 파일로 아래 액션을 만든다.

| 액션명 | 모바일 | PC | 용도 |
|---|---|---|---|
| `tap_action` | 화면 터치 | Space, Mouse Left | 기본 탭, 일반 베기, UI 확인 |
| `alt_slice` | 향후 스와이프/보조 터치 | Mouse Right, Ctrl 또는 Shift | MVP 이후 방향 슬라이스 예비 |
| `debug_restart` | 없음 | R | 개발 중 즉시 재시작 |

`tap_action`의 press/release 시간을 이용해 탭, 탭탭, 롱탭을 구분한다. 별도의 `long_tap_action`을 만들지 말고 한 액션에서 duration으로 판단한다.

권장 판정값:

```gdscript
const DOUBLE_TAP_WINDOW := 0.25
const LONG_TAP_THRESHOLD := 0.45
const TAP_COOLDOWN := 0.12
```

---

## 3. 권장 폴더 구조

아래 구조를 만든다. 이미 존재하는 프로젝트가 있으면 충돌 없이 병합한다.

```text
res://
  assets/
    characters/
    placeholders/
  scenes/
    Main.tscn
    game/
      RunnerStage.tscn
      BossStage.tscn
    player/
      Player.tscn
    objects/
      InteractableObject.tscn
      SlicePiece.tscn
    ui/
      GameHUD.tscn
      ResultPanel.tscn
  scripts/
    Main.gd
    game/
      RunnerStage.gd
      BossStage.gd
      ObjectSpawner.gd
      ParallaxScroller.gd
      GroundLooper.gd
    player/
      PlayerController.gd
      InputInterpreter.gd
    objects/
      InteractableObject.gd
      SlicePiece.gd
      SliceEffectFactory.gd
    ui/
      GameHUD.gd
      ResultPanel.gd
    data/
      ObjectTypes.gd
      GameBalance.gd
```

너무 많은 씬을 만들기 어렵다면 최소 구조로 시작해도 된다. 그러나 `InputInterpreter`, `InteractableObject`, `SliceEffectFactory`, `RunnerStage`, `BossStage`는 분리하는 편이 좋다.

---

## 4. 루트 캐릭터 에셋 처리

사용자가 캐릭터 이미지 파일을 프로젝트 루트에 둘 예정이다. Codex는 다음 규칙으로 처리한다.

1. 루트에서 `.png`, `.jpg`, `.jpeg`, `.webp` 파일을 찾는다.
2. `res://assets/characters/` 폴더가 없으면 생성한다.
3. 캐릭터로 추정되는 첫 번째 이미지를 `res://assets/characters/player_default.<ext>`로 이동하거나 복사한다.
4. 이미 같은 파일이 있으면 덮어쓰지 말고 `player_default_2.<ext>`처럼 안전한 이름을 사용한다.
5. 캐릭터 이미지가 없으면 `Player.tscn`은 placeholder 도형으로 만든다.
6. 나중에 에셋을 교체하기 쉽도록 `PlayerController.gd`는 Sprite2D가 없어도 동작해야 한다.

---

## 5. 씬 구성

### 5.1 Main.tscn

역할: 게임 전체 상태 전환.

노드 예시:

```text
Main (Node)
  RunnerStage
  BossStage
  GameHUD
  ResultPanel
```

처음에는 `RunnerStage`만 활성화하고 `BossStage`, `ResultPanel`은 숨긴다. 러닝 종료 이벤트가 오면 RunnerStage를 멈추고 BossStage를 시작한다.

### 5.2 RunnerStage.tscn

역할: 자동 러닝, 배경/바닥 스크롤, 오브젝트 스폰, 러닝 종료 조건.

노드 예시:

```text
RunnerStage (Node2D)
  BackgroundRoot (Node2D)
    FarLayer (Node2D)
    MidLayer (Node2D)
    NearLayer (Node2D)
  GroundRoot (Node2D)
  ObjectRoot (Node2D)
  SlicePieceRoot (Node2D)
  Player
  ActionZone (Area2D)
  ObjectSpawner
```

`ActionZone`은 플레이어 앞에 위치한 투명 판정 영역이다. 오브젝트가 이 영역에 들어왔을 때 플레이어 입력을 정답/오답으로 판정한다.

### 5.3 Player.tscn

노드 예시:

```text
Player (Node2D)
  VisualRoot (Node2D)
    Sprite2D 또는 placeholder Polygon2D
  SwordArc (Line2D 또는 Polygon2D)
  AnimationPlayer
```

- 캐릭터는 실제 이동하지 않는다.
- 달리기 애니메이션은 placeholder 상태에서는 위아래 2~3px 흔들림과 발 모양 도형 반복으로 대체한다.
- 베기 시 SwordArc를 0.08~0.15초 표시한다.

### 5.4 InteractableObject.tscn

모든 수련 타깃/아이템/위험물의 공통 씬.

권장 노드:

```text
InteractableObject (Area2D)
  VisualRoot (Node2D)
    ColorRect 또는 Polygon2D 또는 Sprite2D
    Label/IconLabel
  CollisionShape2D
```

필수 export 변수:

```gdscript
@export var object_type: StringName
@export var required_action: StringName # "tap", "double_tap", "long_tap", "no_input"
@export var is_good_item: bool
@export var score_value: int
@export var fever_value: int
@export var damage_on_fail: int
```

---

## 6. 게임 오브젝트 타입

`ObjectTypes.gd` 또는 Dictionary로 아래 타입을 구현한다.

| 타입 | 화면 표현 | required_action | is_good_item | 성공 처리 | 실패 처리 |
|---|---|---|---:|---|---|
| `enemy_basic` | 밀짚 수련 인형 | `tap` | false | 절단, 점수 +100, 피버 +6 | 체력 -1 |
| `enemy_fast` | 바퀴 달린 나무색 목각 인형 | `double_tap` | false | 절단, 점수 +150, 피버 +10 | 체력 -1 |
| `enemy_armor` | 나무 판을 방패처럼 붙인 회청색 목각 인형 | `long_tap` | false | 절단, 점수 +150, 피버 +10 | 체력 -1 |
| `coin` | 노란 원형 코인 | `no_input` | true | 접촉 획득, 점수 +20, 코인 값 +20 | 베면 파괴, 보상 없음 |
| `heal` | 초록 회복 아이템 | `no_input` | true | 체력 +1, 최대 3칸 | 베면 파괴, 회복 없음 |
| `fever_orb` | 보라/파랑 피버 오브 | `no_input` | true | 피버 +25, 점수 +50 | 베면 파괴, 피버 없음 |
| `bomb` | 검은 화약통 | `tap` | false | 절단/해체, 점수 +80, 피버 +4 | 체력 -1 |

색상 placeholder:

- 수련 타깃: 밀짚색/나무색/회청색 계열
- 좋은 아이템: 노랑/초록/보라 계열
- 위험물: 검정/빨강 계열

생성된 수련 타깃/위험물 에셋:

- `enemy_basic`: `res://assets/objects/enemy_basic_straw_dummy.png`
- `enemy_fast`: `res://assets/objects/enemy_fast_wheeled_wood_dummy.png`
- `enemy_armor`: `res://assets/objects/enemy_armor_shield_wood_dummy.png`
- `bomb`: `res://assets/objects/bomb_black_powder_keg.png`

렌더링 크기와 높이:

- `GameBalance.PLAYER_RENDER_HEIGHT = 230.0`을 기준으로 한다.
- `enemy_basic`: 플레이어와 같은 높이.
- `enemy_fast`: 플레이어 높이의 1.2배.
- `enemy_armor`: 플레이어 높이의 1.4배.
- `bomb`: 플레이어 높이의 1.3배.
- `coin`, `heal`, `fever_orb`: 플레이어 높이의 0.3배 크기, `SPAWN_Y`보다 플레이어 높이의 0.3배 위에 배치.

---

## 7. 입력 해석 로직

`InputInterpreter.gd`를 만든다. 이 스크립트는 raw input을 게임용 action으로 변환한다.

출력 이벤트:

- `tap_detected`
- `double_tap_detected`
- `long_tap_detected`

권장 로직:

1. `tap_action` pressed 시각을 기록한다.
2. released 시 duration을 계산한다.
3. duration >= `LONG_TAP_THRESHOLD`이면 `long_tap_detected` emit.
4. 아니면 최근 탭 시각과 비교해 `DOUBLE_TAP_WINDOW` 이내면 `double_tap_detected` emit.
5. 그 외에는 임시로 tap 후보를 저장한다.
6. double tap 판정을 위해 tap을 너무 늦게 emit하면 조작감이 둔해질 수 있다. MVP에서는 첫 탭을 즉시 `tap_detected`로 emit하고, 두 번째 탭이 오면 `double_tap_detected`도 추가 emit해도 된다. 이 경우 빠른 타깃은 double_tap만 성공, 기본 타깃은 첫 tap으로 성공한다.

주의: 좋은 아이템은 액션 존 안에 있을 때 어떤 slash 입력이 들어오면 파괴 처리한다. 즉, `no_input` 오브젝트는 입력 이벤트가 없어야 성공한다.

---

## 8. 러닝 판정 로직

`RunnerStage.gd` 또는 별도 Resolver에서 관리한다.

필요 상태:

```gdscript
var current_objects_in_zone: Array[InteractableObject] = []
var score := 0
var coins := 0
var hp := 3 # 하트 3칸, 최대 3
var combo := 0
var fever := 0
var is_fever := false
var run_distance := 0.0
var run_speed := 420.0
```

판정 규칙:

1. 오브젝트가 ActionZone에 들어오면 `current_objects_in_zone`에 넣는다.
2. 입력이 들어오면 가장 가까운 오브젝트를 찾는다.
3. 오브젝트의 `required_action`과 입력이 일치하면 성공 처리한다.
4. 오브젝트가 good item이고 입력이 들어오면 파괴 처리한다.
5. 오브젝트가 ActionZone을 지나쳤는데 처리되지 않았다면:
   - good item이면 획득 처리
   - enemy/bomb이면 실패 처리
6. 피버 중에는 enemy/bomb은 자동 절단, good item은 자동 획득한다.

좋은 아이템을 “베면 안 된다”는 규칙을 반드시 구현한다. 이게 이 게임의 차별점이다.

---

## 9. 절단 물리 연출

`SliceEffectFactory.gd`를 만든다. 입력은 오브젝트의 위치, 색상, 크기, 타입 정도면 충분하다.

절단 시 처리:

1. 원본 InteractableObject의 collision을 끄고 제거한다.
2. `SlicePiece` 2개를 `SlicePieceRoot`에 생성한다.
3. 각 조각은 RigidBody2D로 만든다.
4. 각 조각에 서로 다른 impulse와 torque impulse를 적용한다.
5. 1.2초 뒤 자동 제거한다.

`SlicePiece.tscn` 예시:

```text
SlicePiece (RigidBody2D)
  Polygon2D 또는 ColorRect 대체 Node2D
  CollisionShape2D
  Timer
```

권장 impulse:

```gdscript
left_piece.apply_impulse(Vector2(-160, -360))
right_piece.apply_impulse(Vector2(180, -330))
left_piece.apply_torque_impulse(-4500)
right_piece.apply_torque_impulse(5200)
```

주의:

- impulse는 매 프레임 적용하지 말고, 생성 직후 한 번만 적용한다.
- 조각은 화면 밖으로 나가거나 Timer가 끝나면 삭제한다.
- 초기에는 실제 스프라이트 분할이 아니라 삼각형/반쪽 사각형 Polygon2D로 충분하다.
- 좋은 아이템을 잘못 베었을 때도 조각 연출을 보여주되, 점수/획득은 주지 않는다.

---

## 10. 배경과 바닥 스크롤

실제 캐릭터를 앞으로 이동시키지 않는다.

구현 방식:

- `GroundLooper.gd`: 바닥 타일 여러 개를 왼쪽으로 이동. 화면 밖으로 나간 타일은 오른쪽 끝으로 재배치.
- `ParallaxScroller.gd`: Far/Mid/Near 레이어를 서로 다른 속도로 이동.
- 레이어별 속도 예시:
  - Far: `run_speed * 0.15`
  - Mid: `run_speed * 0.35`
  - Near: `run_speed * 0.65`
  - Ground: `run_speed`
  - Objects: `run_speed`

Godot의 `Parallax2D`를 써도 되고, 단순 Node2D 수동 이동 방식으로 구현해도 된다. 프로토타입에서는 수동 이동이 더 빠를 수 있다. 단, 추후 확장성을 위해 스크롤 레이어를 독립 스크립트로 분리한다.

---

## 11. 오브젝트 스폰

`ObjectSpawner.gd`는 일정 간격으로 오브젝트를 오른쪽 화면 밖에서 생성한다.

권장값:

```gdscript
spawn_x := 1400
spawn_y := 510
min_spawn_interval := 0.65
max_spawn_interval := 1.15
```

초기 스폰 패턴:

1. 첫 10초: enemy_basic, coin 위주
2. 10~20초: enemy_fast, heal 추가
3. 20초 이후: enemy_armor, fever_orb, bomb 추가
4. run_distance 또는 object_count가 일정 값에 도달하면 보스전으로 전환

보스전 전환 기준 MVP:

```gdscript
const OBJECTS_BEFORE_BOSS := 28
```

랜덤만 쓰면 난이도가 튈 수 있으므로, 아래처럼 간단한 배열 패턴을 섞는다.

```text
enemy_basic, coin, enemy_basic, fever_orb, enemy_fast, coin, enemy_armor, heal, bomb
```

---

## 12. 피버 시스템

필수 변수:

```gdscript
var fever := 0
const FEVER_MAX := 100
const FEVER_DURATION := 4.0
```

규칙:

- 수련 타깃과 위험물을 정확히 처리하면 피버 증가.
- `fever_orb`를 먹으면 크게 증가.
- fever가 100 이상이면 즉시 피버 발동.
- 피버 중에는 enemy/bomb이 ActionZone 근처에 오면 자동 절단.
- 피버 중 good item은 자동 획득.
- 피버 중 점수는 2배.
- 피버가 끝나면 fever를 0으로 되돌린다.

UI에는 상단에 fever bar를 표시한다.

---

## 13. 보스전

`BossStage.tscn`과 `BossStage.gd`를 만든다.

흐름:

1. RunnerStage가 끝나면 Main이 BossStage를 활성화한다.
2. 보스와 플레이어가 대치한다.
3. 보스 패턴 아이콘을 화면 중앙에 표시한다.
4. 플레이어가 제한 시간 안에 입력한다.
5. 정답이면 보스 HP -1, 오답이면 플레이어 HP -1.
6. 보스 HP 0이면 승리 결과 화면, 플레이어 HP 0이면 패배 결과 화면.

보스 패턴:

| 패턴 | 요구 입력 | 제한 시간 |
|---|---|---:|
| `boss_opening` | tap | 0.85초 |
| `boss_combo` | double_tap | 1.0초 |
| `boss_guard` | long_tap | 1.2초 |
| `boss_fake` | no_input | 0.8초 |

MVP에서는 보스 체력 5, 플레이어 체력은 러닝에서 남은 hp를 사용한다. 보스전 중 플레이어가 죽으면 결과 화면으로 간다.

---

## 14. UI

`GameHUD.tscn` 필수 표시:

- Score Label
- Heart Icons 3개. 현재 체력만 채우고 숫자는 표시하지 않음
- Combo Label
- Fever Bar
- Boss HP Bar는 보스전에서만 표시
- 입력 안내 텍스트: `TAP / TAP TAP / HOLD / DON'T CUT!`

`ResultPanel.tscn` 필수 표시:

- 결과: WIN 또는 FAIL
- 점수
- 획득 코인
- 최고 점수는 저장까지 구현하지 않아도 되지만, 시간이 되면 `user://save.cfg`로 저장
- Retry 버튼 또는 `Tap to Retry`

---

## 15. 카메라/연출

필수 연출:

1. 일반 베기 성공: 검광 + 히트스톱 + 조각 물리
2. 좋은 아이템 오베기: 조각 물리 + `BROKEN!` 텍스트 + 보상 없음
3. 피버 시작: 화면 플래시 또는 큰 텍스트
4. 보스 타격: 히트스톱을 조금 더 길게
5. 보스 격파: 큰 검광 또는 화면 흔들림

히트스톱은 `Engine.time_scale`을 잠시 낮추는 방식보다, 초보 구현에서는 게임 루프 내부의 `hitstop_timer`로 오브젝트 이동을 잠시 멈추는 방식이 안전하다. 시간이 부족하면 0.05초의 간단한 이동 정지만 구현한다.

---

## 16. 개발 순서

### 1단계: 프로젝트와 입력

- 프로젝트 설정, 가로 해상도, Main.tscn 생성
- InputMap 설정
- Player placeholder 생성
- Space/LMB/모바일 탭이 같은 액션으로 잡히는지 확인

### 2단계: 러너 기본

- 배경 레이어 3개와 바닥 타일 반복 구현
- 캐릭터 고정, 바닥/배경/오브젝트 이동
- ObjectSpawner가 placeholder 오브젝트 생성

### 3단계: 판정

- ActionZone 구현
- enemy_basic과 coin 처리
- tap으로 enemy는 베고 coin은 베면 파괴되게 구현

### 4단계: 입력 확장

- double tap, long tap 구현
- enemy_fast, enemy_armor 추가
- heal, fever_orb, bomb 추가

### 5단계: 절단 연출

- SliceEffectFactory 구현
- SlicePiece 2개 생성, impulse/torque 적용
- Hit flash, sword arc, broken text 추가

### 6단계: 피버

- fever bar 구현
- fever 자동 발동
- fever 중 자동 절단/자동 획득

### 7단계: 보스전과 결과

- BossStage 구현
- tap/double/long/no_input 패턴
- 결과 화면, retry 구현

---

## 17. 완료 기준

아래가 모두 되면 MVP 완료로 본다.

- [ ] 모바일 가로모드 기준 1280x720 화면 구성
- [ ] PC에서 Space/LMB로 기본 탭 가능
- [ ] 캐릭터가 고정되어 있고 배경/바닥/오브젝트가 이동해 달리는 것처럼 보임
- [ ] 최소 7개 오브젝트 타입 구현: basic, fast, armor, coin, heal, fever_orb, bomb
- [ ] 좋은 아이템은 베면 파괴되고 획득되지 않음
- [ ] 수련 타깃/위험물을 정답 입력으로 처리하면 두 조각이 튀고 회전함
- [ ] 피버 게이지와 피버 자동 처리 구현
- [ ] 러닝 종료 후 보스전으로 전환
- [ ] 보스전에서 tap/double/long/no_input 패턴 처리
- [ ] 결과 화면과 retry 구현
- [ ] 캐릭터 이미지가 루트에 있으면 assets/characters로 이동/사용, 없으면 placeholder로 동작

---

## 18. 주의할 점

- 게임을 복잡하게 만들지 말 것. 이동, 점프, 대시, 방어, 방향 슬라이스는 MVP 이후로 미룬다.
- 좋은 아이템과 위험 오브젝트의 색/형태를 확실히 구분할 것.
- 물리 조각은 수명 제한을 걸어 성능 문제를 피할 것.
- 보스전은 20초 이하로 짧게 만들 것.
- 실제 이미지가 없어도 제출 가능한 수준의 placeholder 미학을 유지할 것.
- 하이퍼캐주얼답게 실패 후 즉시 재시작이 가능해야 한다.

---

## 19. 참고 구현 키워드

- `Area2D`: ActionZone, 오브젝트 충돌/진입 감지
- `RigidBody2D`: 베인 조각 물리 연출
- `apply_impulse`, `apply_torque_impulse`: 생성 직후 한 번만 적용
- `Line2D` 또는 `Polygon2D`: 검광 표현
- `ColorRect`, `Polygon2D`, `Label`: 임시 오브젝트/아이콘 표현
- `Timer`: 조각 수명, 보스 패턴 제한 시간
- `InputMap`: 모바일 탭과 PC 입력을 같은 액션으로 묶기
- `Parallax2D` 또는 수동 스크롤 레이어: 2D 깊이감
